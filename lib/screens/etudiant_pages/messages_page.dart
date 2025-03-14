// messages_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'chatgroup_page.dart';
import 'chatclass_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  TextEditingController searchController = TextEditingController();
  String? currentUserId;
  List<String> classes = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          currentUserId = userSnapshot.docs.first.id;
        });
        _fetchClasses();
      }
    }
  }

  Future<void> _fetchClasses() async {
    if (currentUserId == null) return;
    DocumentSnapshot classSnapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(currentUserId)
        .get();

    setState(() {
      classes = List<String>.from(classSnapshot['classes']);
    });
  }

  Future<Map<String, String>> _getRecipientInfo(String chatId) async {
    if (chatId.contains('group')) {
      // Conversation de groupe
      String className = chatId.split('_')[1]; // Supposons que le nom de la classe est la deuxième partie de chatId
      return {'nom': className, 'prenom': '', 'type': 'Classe'};
    } else {
      // Conversation individuelle
      String recipientId = chatId.split('_').firstWhere((id) => id != currentUserId);
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(recipientId).get();

      if (userDoc.exists) {
        String nom = userDoc['nom'];
        String prenom = userDoc['prenom'];
        String type = userDoc['type'];
        return {'nom': nom, 'prenom': prenom, 'type': type};
      } else {
        return {'nom': 'Inconnu', 'prenom': '', 'type': ''};
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Messagerie", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF140C5F),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildClassStatus(),
          Expanded(child: _buildConversationList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageOptions(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher une conversation",
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          // ignore: deprecated_member_use
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildClassStatus() {
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('UserChats')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune conversation de groupe", style: TextStyle(color: Colors.white)));
        }

        // Récupérer les conversations contenant 'group'
        var groupConversations = snapshot.data!.docs.where((doc) {
          return doc.id.contains('group');
        }).toList();

        // Récupérer les conversations des enseignants
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTeacherConversations(),
          builder: (context, teacherConversationsSnapshot) {
            if (teacherConversationsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Combiner les deux listes de conversations
            List<Map<String, dynamic>> allConversations = [];
            allConversations.addAll(groupConversations.map((doc) {
              return {
                'chatId': doc.id,
                'groupName': doc['groupName'],
                'isGroup': doc['isGroup'] ?? false, // Récupérer le champ isGroup
              };
            }));

            if (teacherConversationsSnapshot.hasData) {
              allConversations.addAll(teacherConversationsSnapshot.data!);
            }

            return SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allConversations.length,
                itemBuilder: (context, index) {
                  var conversation = allConversations[index];
                  var chatId = conversation['chatId'];
                  var groupName = conversation['groupName'];
                  bool isGroup = conversation['isGroup'] ?? false; // Vérifier si c'est un groupe

                  return GestureDetector(
                    onTap: () {
                      // Naviguer vers la page appropriée en fonction de isGroup
                      if (isGroup) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatgroupPage(chatId: chatId, recipientName: groupName),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatclassPage(chatId: chatId, recipientName: groupName),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue,
                            child: Text(groupName[0], style: const TextStyle(color: Colors.white, fontSize: 20)),
                          ),
                          const SizedBox(height: 5),
                          Flexible(
                            child: Text(groupName, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTeacherConversations() async {
    List<Map<String, dynamic>> conversations = [];

    if (currentUserId == null) return conversations;

    // Récupérer la classe de l'étudiant
    DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(currentUserId)
        .get();

    if (!studentSnapshot.exists) return conversations;

    String studentClass = studentSnapshot['classe'];

    // Parcourir les enseignants
    QuerySnapshot teachersSnapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .get();

    for (var teacherDoc in teachersSnapshot.docs) {
      // Vérifier si l'enseignant enseigne dans la classe de l'étudiant
      QuerySnapshot matieresSnapshot = await FirebaseFirestore.instance
          .collection('Enseignants')
          .doc(teacherDoc.id)
          .collection('Matieres')
          .get();

      // Vérifier si l'une des matières (documents) a un ID correspondant à la classe de l'étudiant
      bool teachesClass = matieresSnapshot.docs.any((doc) => doc.id == studentClass);

      if (teachesClass) {
        // Récupérer les conversations de l'enseignant pour cette classe
        QuerySnapshot chatsSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(teacherDoc.id)
            .collection('UserChats')
            .where('groupName', isEqualTo: studentClass)
            .get();

        for (var chatDoc in chatsSnapshot.docs) {
          conversations.add({
            'chatId': chatDoc.id,
            'groupName': chatDoc['groupName'],
          });
        }
      }
    }

    return conversations;
  }

  Widget _buildConversationList() {
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('UserChats')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune conversation", style: TextStyle(color: Colors.white)));
        }

        var conversations = snapshot.data!.docs.where((doc) {
          return !doc.id.contains('group');
        }).toList();

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            var conversation = conversations[index];
            var chatId = conversation.id;

            return FutureBuilder<Map<String, String>>(
              future: _getRecipientInfo(chatId),
              builder: (context, recipientSnapshot) {
                if (recipientSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!recipientSnapshot.hasData) {
                  return const Center(child: Text("Erreur de chargement", style: TextStyle(color: Colors.white)));
                }

                var recipientInfo = recipientSnapshot.data!;
                var recipientName = "${recipientInfo['nom']} ${recipientInfo['prenom']}";
                var recipientType = recipientInfo['type'];

                return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUserId)
                      .collection('UserChats')
                      .doc(chatId)
                      .collection('Messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                    if (messageSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Aucun message", style: TextStyle(color: Colors.white)));
                    }

                    var lastMessageDoc = messageSnapshot.data!.docs.first;
                    var lastMessage = lastMessageDoc['text'] ?? "Aucun message";
                    var time = lastMessageDoc['timestamp']?.toDate() ?? DateTime.now();
                    var formattedTime = "${time.hour}:${time.minute}";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(recipientType ?? '', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: Text(formattedTime, style: const TextStyle(color: Colors.grey)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatPage(chatId: chatId, recipientName: recipientName)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showNewMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: const Text("Enseignant"),
              onTap: () {
                Navigator.pop(context);
                _showTeacherSelection(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.red),
              title: const Text("Administration"),
              onTap: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => ChatPage(chatId: "${currentUserId}_admin", recipientName: "Administration"))
              );
              },
            ),
          ],
        );
      },
    );
  }

  void _showTeacherSelection(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Rechercher un enseignant",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('Enseignants').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Aucun enseignant trouvé"));
                      }

                      var teachers = snapshot.data!.docs.where((teacher) {
                        var teacherName = "${teacher['nom']} ${teacher['prenom']}";
                        return teacherName.toLowerCase().contains(searchController.text.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: teachers.length,
                        itemBuilder: (context, index) {
                          var teacher = teachers[index];
                          var teacherName = "${teacher['nom']} ${teacher['prenom']}";

                          return ListTile(
                            title: Text(teacherName, style: const TextStyle(color: Colors.black)),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatId: "${currentUserId}_${teacher.id}",
                                    recipientName: teacherName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
