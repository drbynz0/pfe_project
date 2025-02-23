import 'package:flutter/material.dart';

class MessagesConducteurPage extends StatefulWidget {
  const MessagesConducteurPage({super.key});

  @override
  MessagesConducteurPageState createState() => MessagesConducteurPageState();
}

class MessagesConducteurPageState extends State<MessagesConducteurPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> conversations = [
    {"name": "Administration", "lastMessage": "Changement d'itinéraire demain.", "time": "08:30"},
    {"name": "Parents Groupe", "lastMessage": "Merci pour votre service !", "time": "10:15"},
    {"name": "Élève Karim", "lastMessage": "Je serai en retard demain...", "time": "11:45"},
  ];
  List<String> groupes = ["Parents", "Élèves", "Administration"];

  List<bool> selectedEleves = List.generate(10, (index) => false); // 10 élèves
  List<bool> selectedParents = List.generate(10, (index) => false); // 10 parents

  bool selectAllEleves = false; // Contrôle si toutes les cases des élèves doivent être sélectionnées
  bool selectAllParents = false; // Contrôle si toutes les cases des parents doivent être sélectionnées

  // Toggle sélection/désélection de tous les élèves
  void _toggleSelectAllEleves() {
    setState(() {
      selectAllEleves = !selectAllEleves;
      for (int i = 0; i < selectedEleves.length; i++) {
        selectedEleves[i] = selectAllEleves;
      }
    });
  }

  // Toggle sélection/désélection de tous les parents
  void _toggleSelectAllParents() {
    setState(() {
      selectAllParents = !selectAllParents;
      for (int i = 0; i < selectedParents.length; i++) {
        selectedParents[i] = selectAllParents;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Messagerie Conducteur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF140C5F),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGroupStatus(),
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
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (query) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildGroupStatus() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groupes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Text(groupes[index][0], style: const TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: Text(groupes[index], style: const TextStyle(color: Colors.white)),
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
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(conversation["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(conversation["lastMessage"], maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(conversation["time"], style: const TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
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
              title: const Text("Élève"),
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
              onTap: () {},
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
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Élèves"),
                  Tab(text: "Parents"),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _buildUserSelectionList("Élève", selectedEleves, _toggleSelectAllEleves, selectAllEleves),
                    _buildUserSelectionList("Parent", selectedParents, _toggleSelectAllParents, selectAllParents),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
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

  // Liste des utilisateurs avec possibilité de cocher/décocher
  Widget _buildUserSelectionList(String type, List<bool> selectionList, Function toggleSelectAll, bool selectAll) {
    return Column(
      children: [
        // Un seul bouton pour sélectionner ou désélectionner toutes les cases
        ElevatedButton(
          onPressed: () => toggleSelectAll(),
          child: Text(selectAll ? "Désélectionner tout" : "Tout sélectionner"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return CheckboxListTile(
                title: Text("$type $index"),
                value: selectionList[index],
                onChanged: (bool? value) {
                  setState(() {
                    selectionList[index] = value ?? false;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
