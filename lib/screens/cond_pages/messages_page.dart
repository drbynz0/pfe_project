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
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  
  // State variables
  String? _currentUserId;
  final List<String> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _getCurrentUserId();
    _searchController.addListener(_filterConversations);
  }

  // ======================
  // Firebase Data Methods
  // ======================

  Future<void> _getCurrentUserId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          setState(() {
            _currentUserId = userSnapshot.docs.first.id;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      // Consider showing an error to the user
    }
  }

  Future<Map<String, String>> _getRecipientInfo(String chatId) async {
    try {
      if (chatId.contains('group')) {
        return _handleGroupChatInfo(chatId);
      } else {
        return await _handleIndividualChatInfo(chatId);
      }
    } catch (e) {
      debugPrint('Error getting recipient info: $e');
      return {'nom': 'Erreur', 'prenom': '', 'type': ''};
    }
  }

  Map<String, String> _handleGroupChatInfo(String chatId) {
    final parts = chatId.split('_');
    if (parts.length >= 3) {
      final className = parts[1];
      return {'nom': className, 'prenom': '', 'type': 'Classe'};
    }
    return {'nom': 'Groupe', 'prenom': '', 'type': 'Groupe'};
  }

  Future<Map<String, String>> _handleIndividualChatInfo(String chatId) async {
    final recipientId = chatId.split('_').firstWhere((id) => id != _currentUserId);
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(recipientId)
        .get();

    if (userDoc.exists) {
      return {
        'nom': userDoc['nom'] ?? 'Inconnu',
        'prenom': userDoc['prenom'] ?? '',
        'type': userDoc['type'] ?? ''
      };
    }
    return {'nom': 'Inconnu', 'prenom': '', 'type': ''};
  }

  // ======================
  // UI Filter Methods
  // ======================

  void _filterConversations() {
    setState(() {
    });
  }

  // ======================
  // Chat Creation Methods
  // ======================

  Future<void> _startGroupChat() async {
    if (_selectedUsers.isEmpty || _selectedUsers.length < 2) return;

    try {
      final participants = [_currentUserId!, ..._selectedUsers];
      final conversationType = participants.any((p) => p.startsWith('P')) 
          ? 'Parents' 
          : 'Etudiants';
      
      final groupId = "${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}_group_Chat($conversationType)";

      final batch = FirebaseFirestore.instance.batch();
      
      for (final participant in participants) {
        final docRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(participant)
            .collection('UserChats')
            .doc(groupId);
        
        batch.set(docRef, {
          'chatId': groupId,
          'isGroup': true,
          'type_group': conversationType,
          'groupName': participants,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatgroupPage(
            chatId: groupId,
            recipientName: conversationType,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error starting group chat: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création du groupe')),
      );
    }
  }

  // ======================
  // UI Building Methods
  // ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildClassStatus(),
          const SizedBox(height: 10),
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
        controller: _searchController,
        decoration: InputDecoration(
          labelText: "Rechercher une conversation",
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          // ignore: deprecated_member_use
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => _filterConversations(),
      ),
    );
  }

  Widget _buildClassStatus() {
    if (_currentUserId == null) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUserId)
          .collection('UserChats')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 90,
            child: Center(
              child: Text(
                "Aucune conversation de groupe",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final groupConversations = snapshot.data!.docs.where((doc) {
          return doc.id.contains('group');
        }).toList();

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groupConversations.length,
            itemBuilder: (context, index) {
              final conversation = groupConversations[index];
              final chatId = conversation.id;
              final typeGroup = conversation['type_group'];
              final isGroup = conversation['isGroup'] ?? false;

              return _buildGroupAvatar(chatId, typeGroup, isGroup);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupAvatar(String chatId, String typeGroup, bool isGroup) {
    return GestureDetector(
      onTap: isGroup
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatgroupPage(
                    chatId: chatId,
                    recipientName: typeGroup,
                  ),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Text(
                typeGroup.isNotEmpty ? typeGroup[0] : 'G',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 60,
              child: Text(
                typeGroup,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUserId)
          .collection('UserChats')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Aucune conversation",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final conversations = snapshot.data!.docs.where((doc) {
          return !doc.id.contains('group');
        }).toList();

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final chatId = conversation.id;

            return FutureBuilder<Map<String, String>>(
              future: _getRecipientInfo(chatId),
              builder: (context, recipientSnapshot) {
                if (recipientSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildConversationShimmer();
                }

                if (!recipientSnapshot.hasData) {
                  return const ListTile(
                    title: Text("Erreur de chargement"),
                  );
                }

                return _buildConversationItem(
                  chatId, 
                  recipientSnapshot.data!,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildConversationShimmer() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text("Chargement..."),
        subtitle: Text("..."),
      ),
    );
  }

  Widget _buildConversationItem(String chatId, Map<String, String> recipientInfo) {
    final recipientName = "${recipientInfo['nom']} ${recipientInfo['prenom']}";
    final recipientType = recipientInfo['type'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUserId)
          .collection('UserChats')
          .doc(chatId)
          .collection('Messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, messageSnapshot) {
        if (messageSnapshot.connectionState == ConnectionState.waiting) {
          return _buildConversationShimmer();
        }

        String lastMessage = "Aucun message";
        String formattedTime = "--:--";

        if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
          final lastMessageDoc = messageSnapshot.data!.docs.first;
          lastMessage = lastMessageDoc['text'] ?? "Aucun message";
          final time = lastMessageDoc['timestamp']?.toDate() ?? DateTime.now();
          formattedTime = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
        }

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
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recipientType != null && recipientType.isNotEmpty)
                  Text(
                    recipientType,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            trailing: Text(
              formattedTime,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatId: chatId,
                    recipientName: recipientName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ======================
  // Bottom Sheet Methods
  // ======================

  void _showNewMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  "Nouveau message",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              _buildOptionTile(
                context,
                icon: Icons.person,
                color: Colors.blue,
                title: "Étudiant",
                onTap: () {
                  Navigator.pop(context);
                  _showStudentSelection(context);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.group,
                color: Colors.green,
                title: "Parent",
                onTap: () {
                  Navigator.pop(context);
                  _showParentSelection(context);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.business,
                color: Colors.red,
                title: "Administration",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: "${_currentUserId}_admin",
                        recipientName: "Administration",
                      ),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.people,
                color: Colors.purple,
                title: "Conversation groupée",
                onTap: () {
                  Navigator.pop(context);
                  _showGroupChatSelection(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showGroupChatSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2,
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
                height: MediaQuery.of(context).size.height * 0.5,
                child: TabBarView(
                  children: [
                    _buildUserSelectionList("Étudiant"),
                    _buildUserSelectionList("Parent"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
      future: FirebaseFirestore.instance
          .collection(type == "Étudiant" ? 'Etudiants' : 'Parents')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Aucun $type trouvé"));
        }

        final users = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userName = "${user['nom']} ${user['prenom']}";
                final className = type == "Étudiant" ? user['classe'] : "";
                final userId = user.id;

                return CheckboxListTile(
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "$userName ",
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        if (className.isNotEmpty)
                          TextSpan(
                            text: "($className)",
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  value: _selectedUsers.contains(userId),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedUsers.add(userId);
                      } else {
                        _selectedUsers.remove(userId);
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

  void _showStudentSelection(BuildContext context) {
    _showUserSelectionBottomSheet(
      context,
      collection: 'Etudiants',
      title: "Rechercher un étudiant",
      builder: (user) {
        final userName = "${user['nom']} ${user['prenom']}";
        final studentClass = user['classe'];
        return ListTile(
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "$userName "),
                TextSpan(
                  text: "($studentClass)",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                  chatId: "${_currentUserId}_${user.id}",
                  recipientName: userName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showParentSelection(BuildContext context) {
    _showUserSelectionBottomSheet(
      context,
      collection: 'Parents',
      title: "Rechercher un parent",
      builder: (user) {
        final userName = "${user['nom']} ${user['prenom']}";
        return ListTile(
          title: Text(userName),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatId: "${_currentUserId}_${user.id}",
                  recipientName: userName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserSelectionBottomSheet(
    BuildContext context, {
    required String collection,
    required String title,
    required Widget Function(DocumentSnapshot) builder,
  }) {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: title,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection(collection)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text("Aucun résultat trouvé"),
                          );
                        }

                        final filteredUsers = snapshot.data!.docs.where((user) {
                          final userName =
                              "${user['nom']} ${user['prenom']}".toLowerCase();
                          return userName.contains(
                              searchController.text.toLowerCase());
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            return builder(filteredUsers[index]);
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