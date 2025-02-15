import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MessagesPage(),
    );
  }
}

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<String> selectedUsers = [];
  TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isSendingMessage = false;
  bool showNewChat = true;
  bool showSelectionPage = false;

  // Liste des chats précédents (exemple)
  List<Map<String, dynamic>> previousChats = [
    {
      "users": ["Parent 1", "Étudiant 1"],
      "messages": [
        {"text": "Bonjour, comment ça va ?", "isSent": true},
        {"text": "Bien, et toi ?", "isSent": false}
      ]
    },
    {
      "users": ["Parent 2", "Étudiant 2"],
      "messages": [
        {"text": "Salut ! Tout va bien ?", "isSent": true},
        {"text": "Oui, merci !", "isSent": false}
      ]
    }
  ];

  void _sendMessage() {
    if (messageController.text.isNotEmpty && selectedUsers.isNotEmpty) {
      setState(() {
        isSendingMessage = true;
      });
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          messages.add({"text": messageController.text, "isSent": true});
          messageController.clear();
          isSendingMessage = false;
        });
      });
    }
  }

  void _openSelectionPage() {
    setState(() {
      showSelectionPage = true;
    });
  }

  void _toggleChatView(bool showNewChat) {
    setState(() {
      this.showNewChat = showNewChat;
      if (showNewChat) {
        showSelectionPage = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 64, 86, 251),
        title: Text(
          selectedUsers.isNotEmpty
              ? 'Chat avec ${selectedUsers.join(", ")}'
              : 'Sélectionnez des utilisateurs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add),
            onPressed: _openSelectionPage,
          ),
        ],
      ),
      body: Container(
        color: showNewChat ? Colors.blue[50] : Colors.purple[50],
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _toggleChatView(true),
                    child: Text('Nouveau Chat'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color.fromRGBO(91, 73, 94, 1)),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      )),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _toggleChatView(false),
                    child: Text('Mes Chats'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(const Color.fromRGBO(91, 73, 94, 1)),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      )),
                    ),
                  ),
                ],
              ),
            ),
            if (showNewChat) ...[
              if (showSelectionPage) ...[
                Expanded(child: SelectionPage(onSelectUsers: (users) {
                  setState(() {
                    selectedUsers = users;
                  });
                })),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Align(
                        alignment: message["isSent"]
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: message["isSent"]
                                ? Colors.purpleAccent
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            message["text"],
                            style: TextStyle(
                              color: message["isSent"] ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isSendingMessage)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.purpleAccent),
                        onPressed: selectedUsers.isEmpty ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: previousChats.length,
                  itemBuilder: (context, index) {
                    final chat = previousChats[index];
                    return ListTile(
                      title: Text(
                        'Chat avec ${chat["users"].join(", ")}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      tileColor: Colors.purple[50],
                      onTap: () {
                        setState(() {
                          selectedUsers = List.from(chat["users"]);
                          messages = List.from(chat["messages"]);
                          showNewChat = true;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SelectionPage extends StatefulWidget {
  final Function(List<String>) onSelectUsers;
  SelectionPage({required this.onSelectUsers});

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  List<String> parents = ['Parent 1', 'Parent 2'];
  List<String> students = ['Étudiant 1', 'Étudiant 2'];
  List<String> selectedUsers = [];
  TextEditingController searchController = TextEditingController();
  String category = 'Administration';
  List<String> filteredUsers = [];
  bool selectAllParents = false;
  bool selectAllStudents = false;

  @override
  void initState() {
    super.initState();
    filteredUsers = ['Administration']; // Par défaut, afficher l'administration
  }

  void _filterUsers(String query) {
    setState(() {
      if (category == 'Parents') {
        filteredUsers = parents
            .where((user) => user.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else if (category == 'Étudiants') {
        filteredUsers = students
            .where((user) => user.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            'Sélectionnez les utilisateurs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: category,
            onChanged: (String? newValue) {
              setState(() {
                category = newValue!;
                _filterUsers('');
                selectAllParents = false;
                selectAllStudents = false;
              });
            },
            items: ['Administration', 'Parents', 'Étudiants']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          if (category == 'Parents' || category == 'Étudiants')
            Column(
              children: [
                CheckboxListTile(
                  title: Text("Sélectionner tout ${category.toLowerCase()}s"),
                  value: category == 'Parents' ? selectAllParents : selectAllStudents,
                  onChanged: (bool? value) {
                    setState(() {
                      if (category == 'Parents') {
                        selectAllParents = value!;
                        if (selectAllParents) {
                          selectedUsers.addAll(parents);
                        } else {
                          selectedUsers.removeWhere((user) => parents.contains(user));
                        }
                      } else if (category == 'Étudiants') {
                        selectAllStudents = value!;
                        if (selectAllStudents) {
                          selectedUsers.addAll(students);
                        } else {
                          selectedUsers.removeWhere((user) => students.contains(user));
                        }
                      }
                    });
                  },
                ),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un ${category.toLowerCase()}...',
                    suffixIcon: Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                  onChanged: _filterUsers,
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(filteredUsers[index]),
                  value: selectedUsers.contains(filteredUsers[index]),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedUsers.add(filteredUsers[index]);
                      } else {
                        selectedUsers.remove(filteredUsers[index]);
                      }
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedUsers.isEmpty
                ? null
                : () {
                    widget.onSelectUsers(selectedUsers);
                    Navigator.pop(context);
                  },
            child: Text('Commencer le chat'),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 140, 116, 144)),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ))),
          ),
        ],
      ),
    );
  }
}
