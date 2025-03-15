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
  List<String> selectedUsers = [];
  List<Map<String, dynamic>> allConversations = []; // Liste de toutes les conversations
  List<Map<String, dynamic>> filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    searchController.addListener(_filterConversations); 
  }

  @override
  void dispose() {
    searchController.dispose(); // Nettoyer le contrôleur
    super.dispose();
  }

  void _filterConversations() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredConversations = allConversations.where((conversation) {
        final groupName = conversation['groupName'].toString().toLowerCase();
        return groupName.contains(query);
      }).toList();
    });
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

  Future<void> _createClassConversations() async {
    if (currentUserId == null) return;

    // Récupérer les classes enseignées par l'enseignant
    QuerySnapshot classSnapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .doc(currentUserId)
        .collection('Matieres')
        .get();

    if (classSnapshot.docs.isEmpty) return;

    // Parcourir chaque classe et créer une conversation
    for (var classDoc in classSnapshot.docs) {
      String className = classDoc.id;
      String chatId = "${currentUserId}_${className}_group";

      // Vérifier si la conversation existe déjà
      DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection('UserChats')
          .doc(chatId)
          .get();

      if (!chatSnapshot.exists) {
        // Créer la conversation dans Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserId)
            .collection('UserChats')
            .doc(chatId)
            .set({
          'chatId': chatId,
          'groupName': className,
          'isGroup': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _fetchClasses() async {
    if (currentUserId == null) return;

    QuerySnapshot classSnapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .doc(currentUserId)
        .collection('Matieres')
        .get();

    setState(() {
      classes = classSnapshot.docs.map((doc) => doc.id).toList();
    });

    // Créer les conversations pour chaque classe
    await _createClassConversations();
  }

  Future<Map<String, String>> _getRecipientInfo(String chatId) async {
    if (chatId.contains('group')) {
      // Conversation de groupe
      List<String> parts = chatId.split('_');
      if (parts.length >= 3) {
        String className = parts[1]; // Le nom de la classe est la deuxième partie
        return {'nom': className, 'prenom': '', 'type': 'Classe'};
      } else {
        return {'nom': 'Groupe', 'prenom': '', 'type': 'Groupe'};
      }
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
        onChanged: (value) {
          _filterConversations(); // Filtrer les conversations à chaque changement de texte
        },
      ),
    );
  }

  Widget _buildClassStatus() {
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
          return const Center(child: Text("Aucune conversation de groupe", style: TextStyle(color: Colors.white)));
        }

        var groupConversations = snapshot.data!.docs.where((doc) {
          return doc.id.contains('group');
        }).toList();

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groupConversations.length,
            itemBuilder: (context, index) {
              var conversation = groupConversations[index];
              var chatId = conversation.id;
              var groupName = conversation['groupName'];
              bool isGroup = conversation['isGroup'] ?? false;

              return GestureDetector(
                onTap: () {
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
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Étudiant"),
              onTap: () {
                Navigator.pop(context);
                _showStudentSelection(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: const Text("Parent"),
              onTap: () {
                Navigator.pop(context);
                _showParentSelection(context);
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
            ListTile(
              leading: const Icon(Icons.people, color: Colors.purple),
              title: const Text("Conversation groupée"),
              onTap: () {
                Navigator.pop(context);
                _showGroupChatSelection(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showGroupChatSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 2, // Nombre d'onglets
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Étudiants"),
                  Tab(text: "Parents"),
                ],
              ),
              SizedBox(
                height: 300, // Définit une hauteur fixe pour éviter l'overflow
                child: TabBarView(
                  children: [
                    _buildUserSelectionList("Étudiant"),
                    _buildUserSelectionList("Parent"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _startGroupChat();
                    Navigator.pop(context);
                  },
                  child: const Text("Lancer la conversation"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserSelectionList(String type) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(type == "Étudiant" ? 'Etudiants' : 'Parents').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Aucun $type trouvé"));
        }

        var users = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];
                var userName = "${user['nom']} ${user['prenom']}";
                var className = "";
                if(type == "Étudiant") {
                  className = "($user['classe'])";
                } else {
                 className = "";
                }
                var userId = user.id;

                return CheckboxListTile(
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "$userName ",
                                    style: const TextStyle(fontSize: 16.0, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: className,
                                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    value: selectedUsers.contains(userId),
                    onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedUsers.add(userId);
                      } else {
                        selectedUsers.remove(userId);
                      }
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _startGroupChat() async {
    if (selectedUsers.isEmpty || selectedUsers.length < 2) return;

    List<String> participants = [currentUserId!, ...selectedUsers];

    String conversationType = participants.any((participant) => participant.startsWith('P')) ? 'Parents' : 'Etudiants';
    String groupId = "${currentUserId}_${DateTime.now().millisecondsSinceEpoch}_group_Chat($conversationType)";

    // Ajouter une entrée dans chaque participant pour qu'ils puissent récupérer la conversation
    for (String participant in participants) {
      await FirebaseFirestore.instance.collection('Users').doc(participant).collection('UserChats').doc(groupId).set({
        'chatId': groupId,
        'isGroup': true,
        'groupName': participants,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => ChatgroupPage(chatId: groupId, recipientName: 'Group Chat($conversationType)'),
      ),
    );
  }

  void _showStudentSelection(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container (
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Rechercher un étudiant",
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
                    future: FirebaseFirestore.instance.collection('Etudiants').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Aucun étudiant trouvé"));
                      }

                      var students = snapshot.data!.docs.where((student) {
                        var studentName = "${student['nom']} ${student['prenom']}";
                        return studentName.toLowerCase().contains(searchController.text.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var student = students[index];
                          var studentName = "${student['nom']} ${student['prenom']}";
                          var studentClass = student['classe'];

                          return ListTile(
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "$studentName ",
                                    style: const TextStyle(fontSize: 16.0, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: "($studentClass)",
                                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatId: "${currentUserId}_${student.id}",
                                    recipientName: studentName,
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
            ),

            );

          },
        );
      },
    );
  }

  void _showParentSelection(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Rechercher un parent",
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
                      future: FirebaseFirestore.instance.collection('Parents').get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("Aucun parent trouvé"));
                        }

                        var parents = snapshot.data!.docs.where((parent) {
                          var parentName = "${parent['nom']} ${parent['prenom']}";
                          return parentName.toLowerCase().contains(searchController.text.toLowerCase());
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: parents.length,
                          itemBuilder: (context, index) {
                            var parent = parents[index];
                            var parentName = "${parent['nom']} ${parent['prenom']}";

                            return ListTile(
                              title: Text(parentName, style: const TextStyle(color: Colors.black)),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      chatId: "${currentUserId}_${parent.id}",
                                      recipientName: parentName,
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
              ),
            );
          },
        );
      },
    );
  }
}
