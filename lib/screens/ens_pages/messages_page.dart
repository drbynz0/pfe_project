// messages_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'chatgroup_page.dart';

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
    QuerySnapshot classSnapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .doc(currentUserId)
        .collection('Matieres')
        .get();

    setState(() {
      classes = classSnapshot.docs.map((doc) => doc.id).toList();
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
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: classes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatgroupPage(chatId: "${currentUserId}_${classes[index]}_group", recipientName: classes[index]),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Text(classes[index][0], style: const TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: Text(classes[index], style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList() {
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('Chats').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune conversation", style: TextStyle(color: Colors.white)));
        }

        var conversations = snapshot.data!.docs.where((doc) {
          return doc.id.contains(currentUserId!);
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
                      .collection('Chats')
                      .doc(chatId)
                      .collection('messages')
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
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: const Text("Parent"),
              onTap: () {},
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
                    Navigator.pop(context);
                    // Ajouter la conversation groupée aux conversations en cours
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
    return ListView.builder(
      itemCount: 10, // Exemple d'affichage de 10 utilisateurs
      itemBuilder: (context, index) {
        return CheckboxListTile(
          title: Text("$type $index"),
          value: false,
          onChanged: (bool? value) {},
        );
      },
    );
  }
}
