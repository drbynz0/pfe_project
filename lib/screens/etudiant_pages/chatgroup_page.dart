import 'package:flutter/material.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
// ignore: unused_import
import 'package:path/path.dart' as path;

class ChatgroupPage extends StatefulWidget {
  final String chatId;
  final String recipientName;

  const ChatgroupPage({super.key, required this.chatId, required this.recipientName});

  @override
  ChatgroupPageState createState() => ChatgroupPageState();
}

class ChatgroupPageState extends State<ChatgroupPage> {
  TextEditingController messageController = TextEditingController();
  String? currentUserId;
  String? receiverId;
  PlatformFile? selectedFile;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _getReceiverId();
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
      }
    }
  }

  void _getReceiverId() {
    if (widget.chatId.contains('_')) {
      List<String> ids = widget.chatId.split('_');
      if (ids.length == 2) {
        for(int i = 0; i < ids.length; i++) {
          if (ids[i] != currentUserId && ids[i] != "group") {
            receiverId = ids[i];
            break;
          }
        }
      }
    }
  }

  Future<String> _getUserInfo(String? userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (userDoc.exists) {
      String nom = userDoc['nom'];
      String prenom = userDoc['prenom'];
      return "$nom $prenom";
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: Text("Groupe Chat (${widget.recipientName})", style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (selectedFile != null) _buildFilePreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection("UserChats")
          .doc(widget.chatId)
          .collection("Messages")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun message"));
        }

        var messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            bool isMe = message["sender_id"] == currentUserId;
            return _buildMessageItem(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message, bool isMe) {
    bool isFileMessage = message.data() != null && (message.data() as Map<String, dynamic>).containsKey('file_url');
    return Stack(
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7, // 70% de la largeur de l'écran
            ),
            child: isFileMessage ? _buildFileMessage(message, isMe) : _buildTextMessage(message, isMe),
          ),
        ),
        if (isMe)
          Positioned(
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              onSelected: (value) {
                if (value == 'Modifier') {
                  _showEditMessageDialog(message);
                } else if (value == 'Supprimer') {
                  _showDeleteConfirmationDialog(message);
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Modifier', 'Supprimer'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextMessage(DocumentSnapshot message, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                FutureBuilder<String>(
                  future: _getUserInfo(message["sender_id"]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Chargement...", style: TextStyle(color: Colors.grey));
                    }
                    if (snapshot.hasError) {
                      return const Text("Erreur", style: TextStyle(color: Colors.grey));
                    }
                    return Text(
                      snapshot.data ?? '',
                      style: TextStyle(
                        color: Colors.grey, // Couleur du texte pour le nom de l'expéditeur
                        fontSize: 12, // Taille de police plus petite pour le nom
                      ),
                    );
                  },
                ),
              Text(
                message["text"],
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage(DocumentSnapshot message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message["file_name"], style: TextStyle(color: isMe ? Colors.white : Colors.black)),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          onPressed: () => _downloadFile(message["file_url"]),
          icon: const Icon(Icons.download),
          label: const Text("Télécharger"),
        ),
        if (isMe)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Supprimer') {
                _showDeleteConfirmationDialog(message);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Supprimer'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
      ],
    );
  }

  void _showEditMessageDialog(DocumentSnapshot message) {
    TextEditingController editController = TextEditingController(text: message["text"]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier le message"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: "Écrire un message..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUserId)
                    .collection("UserChats")
                    .doc(widget.chatId)
                    .collection("Messages")
                    .doc(message.id)
                    .update({"text": editController.text});
                if (mounted) {
                // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
              child: const Text("Modifier"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(DocumentSnapshot message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Voulez-vous vraiment supprimer ce message ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUserId)
                    .collection("UserChats")
                    .doc(widget.chatId)
                    .collection("Messages")
                    .doc(message.id)
                    .delete();
                if (mounted) {
                // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blue),
            onPressed: _showFilePicker,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              decoration: InputDecoration(
                hintText: "Écrire un message...",
                hintStyle: const TextStyle(color: Color.fromARGB(255, 61, 60, 60)),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Text(selectedFile?.name ?? 'No file selected'),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              setState(() {
                selectedFile = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _uploadFile,
          ),
        ],
      ),
    );
  }

  void _showFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  void _uploadFile() async {
    if (selectedFile == null) return;

    String fileName = selectedFile!.name; // ✅ Récupérer le nom du fichier sans erreur
    Reference storageRef = FirebaseStorage.instance.ref().child('chat_files/${widget.chatId}/$fileName');

    UploadTask uploadTask;

    if (kIsWeb) {
      // ✅ Web : Utiliser Blob
      Uint8List? fileBytes = selectedFile!.bytes;
      if (fileBytes == null) return;

      final blob = html.Blob([fileBytes]);
      uploadTask = storageRef.putBlob(blob);
    } else {
      // ✅ Mobile : Utiliser File
      File file = File(selectedFile!.path!);
      uploadTask = storageRef.putFile(file);
    }

    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection("UserChats")
        .doc(widget.chatId)
        .collection("Messages")
        .add({
      "sender_id": currentUserId,
      "receiver_id": receiverId,
      "text": "",
      "file_url": downloadUrl,
      "file_name": fileName,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    setState(() {
      selectedFile = null;
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      selectedFile = result.files.first;
    }
  }

void _sendMessage() async {
  String messageText = messageController.text.trim();
  if (messageText.isEmpty) return;

  if (currentUserId == null) return;

  // Référence à la collection UserChats de l'utilisateur actuel
  DocumentReference chatDocRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUserId)
      .collection("UserChats")
      .doc(widget.chatId);

  // Vérifiez si la collection de messages est vide
  CollectionReference messagesCollectionRef = chatDocRef.collection("Messages");
  DocumentSnapshot chatDocSnapshot = await chatDocRef.get();

  if (!chatDocSnapshot.exists) {
    // Créez le document de chat s'il n'existe pas
    await chatDocRef.set({
      'participants': [currentUserId, widget.recipientName],
      'isGroup': true,
      'groupName': widget.recipientName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Ajoutez le message à la collection de messages de l'utilisateur actuel
  await messagesCollectionRef.add({
    "sender_id": currentUserId,
    "receiver_id": widget.recipientName,
    "text": messageText,
    "timestamp": FieldValue.serverTimestamp(),
    "isRead": false,
  });

  // Parcourir tous les utilisateurs pour envoyer le message aux participants
  QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();

  for (var userDoc in usersSnapshot.docs) {
    String userId = userDoc.id;

    // Exclure l'utilisateur actuel (currentUserId)
    if (userId == currentUserId) continue;

    // Vérifier si l'utilisateur a une conversation avec le chatId correspondant
    DocumentReference userChatRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection("UserChats")
        .doc(widget.chatId);

    DocumentSnapshot userChatSnapshot = await userChatRef.get();

    if (userChatSnapshot.exists) {
      // Ajouter le message à la sous-collection Messages de cette conversation
      await userChatRef.collection("Messages").add({
        "sender_id": currentUserId,
        "receiver_id": widget.recipientName,
        "text": messageText,
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
      });
    }
  }

  messageController.clear();
}

  void _downloadFile(String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
