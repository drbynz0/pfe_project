import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {

  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  bool isAdminSelected = false;
  bool isParentsSelected = false;
  bool isStudentsSelected = false;
  List<String> selectedUsers = [];

  final List<String> parents = ['Ahmed', 'Fatima', 'Mohamed', 'Amina'];
  final List<String> students = ['Youssef', 'Salma', 'Karim', 'Lina'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez des utilisateurs'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 103, 137, 188), Color.fromARGB(255, 139, 114, 141)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Administration
            ListTile(

              title: const Text('Administration', style: TextStyle(color: Colors.white)),

              trailing: Icon(
                isAdminSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: Colors.white,
                
              ),
             onTap: () {
  setState(() {
    isAdminSelected = !isAdminSelected;
    if (isAdminSelected) {
      selectedUsers.add('Administration');
    } else {
      selectedUsers.remove('Administration');
    }
  });
},
            ),
            // Parents
            ListTile(
              title: const Text('Parents', style: TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isParentsSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: Colors.white,
                    ),
                    onPressed: () {
  setState(() {
    if (isParentsSelected) {
      selectedUsers.removeWhere((user) => parents.contains(user));
      isParentsSelected = false;
    } else {
      selectedUsers.addAll(parents.where((user) => !selectedUsers.contains(user)));
      isParentsSelected = true;
    }
  });
},
                  ),
                  IconButton(

                

                    icon: const Icon(Icons.search, color: Colors.white),

                    onPressed: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserSearchScreen(users: parents, title: 'Rechercher un parent'),
                        ),
                      );
                      if (selected != null) {
                        setState(() {
                          selectedUsers.addAll(selected);
                          isParentsSelected = parents.every((parent) => selectedUsers.contains(parent));
                          isAdminSelected = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            // Étudiants
            ListTile(
              title: const Text('Étudiants', style: TextStyle(color: Colors.white)),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isStudentsSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: Colors.white,
                    ),
                    onPressed: () {
  setState(() {
    if (isStudentsSelected) {
      selectedUsers.removeWhere((user) => students.contains(user));
      isStudentsSelected = false;
    } else {
      selectedUsers.addAll(students.where((user) => !selectedUsers.contains(user)));
      isStudentsSelected = true;
    }
  });
},
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserSearchScreen(users: students, title: 'Rechercher un étudiant'),
                        ),
                      );
                      if (selected != null) {
                        setState(() {
                          selectedUsers.addAll(selected);
                          isStudentsSelected = students.every((student) => selectedUsers.contains(student));
                          isAdminSelected = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
           ElevatedButton(
  onPressed: selectedUsers.isNotEmpty || isAdminSelected
      ? () {
          List<String> usersToChat = List.from(selectedUsers);

          // Si Administration est sélectionnée, on l'ajoute séparément
          if (isAdminSelected) {
            usersToChat.add('Administration');
          }

          // Évite les doublons
          usersToChat = usersToChat.toSet().toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                selectedUsers: usersToChat,
                isAdminSelected: isAdminSelected,
              ),
            ),
          );
        }
      : null,
  child: const Text('Commencer le chat'),
),
          ],
        ),
      ),
    );
  }
}

// --- Mise à jour de ChatScreen ---
class ChatScreen extends StatefulWidget {
  final List<String> selectedUsers;
  final bool isAdminSelected;

  const ChatScreen({super.key, required this.selectedUsers, required this.isAdminSelected});

  @override
  ChatScreenState createState() => ChatScreenState();
}



class ChatScreenState extends State<ChatScreen> {
  List<String> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Groupes prédéfinis pour Parents et Étudiants
    Set<String> parents = {'Ahmed', 'Fatima', 'Mohamed', 'Amina'};
    Set<String> students = {'Youssef', 'Salma', 'Karim', 'Lina'};

    // Convertir la liste des utilisateurs sélectionnés en Set pour comparaison
    Set<String> selectedSet = widget.selectedUsers.toSet();

    // Vérifier si tous les parents ou tous les étudiants sont sélectionnés
    bool allParentsSelected = parents.difference(selectedSet).isEmpty && selectedSet.isNotEmpty;
    bool allStudentsSelected = students.difference(selectedSet).isEmpty && selectedSet.isNotEmpty;

    // Déterminer l'affichage du titre
    String chatTitle = 'Chat avec ';

    if (widget.isAdminSelected && widget.selectedUsers.isEmpty) {
      chatTitle += 'Administration';
    } else if (widget.isAdminSelected && widget.selectedUsers.isNotEmpty) {
      chatTitle += 'Administration, ';
    }

    if (allParentsSelected) {
      chatTitle += 'Parents';
    } else if (allStudentsSelected) {
      chatTitle += 'Étudiants';
    } else {
      chatTitle += widget.selectedUsers.join(", ");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chatTitle,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 252, 252, 253), Color.fromARGB(255, 242, 243, 244)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      messages[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Entrez votre message...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 138, 173, 214),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color.fromARGB(255, 189, 109, 165)),
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        setState(() {
                          messages.add(messageController.text);
                          messageController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class UserSearchScreen extends StatefulWidget {
  final List<String> users;
  final String title;

  const UserSearchScreen({super.key, required this.users, required this.title});

  @override
  UserSearchScreenState createState() => UserSearchScreenState();
}

class UserSearchScreenState extends State<UserSearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<String> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: widget.users
                  .where((user) => user.toLowerCase().contains(searchController.text.toLowerCase()))
                  .map((user) {
                bool isSelected = selectedUsers.contains(user);

                return ListTile(
                  title: Text(user),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône + qui change de couleur lorsqu'un utilisateur est sélectionné
                      IconButton(
                        icon: Icon(Icons.add_circle, color: isSelected ? Colors.purple : Colors.blue),
                        onPressed: () {
                          setState(() {
                            if (!isSelected) {
                              selectedUsers.add(user);
                            }
                          });
                        },
                      ),
                      // Icône de suppression
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedUsers.remove(user);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, selectedUsers);
            },
            child: const Text('Confirmer la sélection'),
          ),
        ],
      ),
    );
  }
}