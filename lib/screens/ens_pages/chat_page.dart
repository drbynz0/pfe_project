import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
//import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
//import 'dart:typed_data';
// ignore: unused_import
import 'package:path/path.dart' as path;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String recipientName;

  const ChatPage({super.key, required this.chatId, required this.recipientName});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  TextEditingController messageController = TextEditingController();
  String? currentUserId;
  String? receiverId;
  PlatformFile? selectedFile;

  bool _isEmojiVisible = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserId();
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
    _getCurrentUserId();
    if (widget.chatId.contains('_')) {
      List<String> ids = widget.chatId.split('_');
      if (ids[0] == currentUserId) {
        receiverId = ids[1];
      } else {
        receiverId = ids[0];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: Text(widget.recipientName, style: TextStyle(fontSize: 20, color: Colors.white)),
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
              maxWidth: MediaQuery.of(context).size.width * 0.7,
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
    return Text(
      message["text"],
      style: TextStyle(color: isMe ? Colors.white : Colors.black),
      softWrap: true,
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
                    .collection('UserChats')
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
                    .collection('UserChats')
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.blue),
                onPressed: _showFilePicker,
              ),
              IconButton(
                icon: const Icon(Icons.emoji_emotions, color: Colors.orange),
                onPressed: () {
                  FocusScope.of(context).unfocus(); // Fermer le clavier
                  setState(() {
                    _isEmojiVisible = !_isEmojiVisible;
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  focusNode: focusNode,
                  onTap: () {
                    if (_isEmojiVisible) {
                      setState(() {
                        _isEmojiVisible = false;
                      });
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: "Écrire un message...",
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
        Offstage(
          offstage: !_isEmojiVisible,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                messageController.text += emoji.emoji;
                messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: messageController.text.length),
                );
              },
              config: Config(
                columns: 7,
                emojiSizeMax: 32,
                bgColor: Color(0xFFF2F2F2),
                indicatorColor: Colors.blue,
                iconColor: Colors.grey,
                iconColorSelected: Colors.blue,
                backspaceColor: Colors.red,
                recentsLimit: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file),
          const SizedBox(width: 10),
          Expanded(child: Text(selectedFile?.name ?? 'Aucun fichier')),
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
            onPressed: _sendFile,
          ),
        ],
      ),
    );
  }

  void _showFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
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

    if (currentUserId == null || receiverId == null) return;

    // Référence à la collection UserChats de l'utilisateur actuel
    DocumentReference currentUserChatRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .collection('UserChats')
        .doc(widget.chatId);

    // Référence à la collection UserChats du récepteur
    DocumentReference receiverChatRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(receiverId)
        .collection('UserChats')
        .doc(widget.chatId);

    // Vérifiez si la collection UserChats existe pour l'utilisateur actuel
    DocumentSnapshot currentUserChatSnapshot = await currentUserChatRef.get();
    if (!currentUserChatSnapshot.exists) {
      await currentUserChatRef.set({
        'chatId': widget.chatId,
        'isGroup': false,
        'participants': [currentUserId, receiverId],
        'lastMessage': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await currentUserChatRef.update({
        'lastMessage': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Vérifiez si la collection UserChats existe pour le récepteur
    DocumentSnapshot receiverChatSnapshot = await receiverChatRef.get();
    if (!receiverChatSnapshot.exists) {
      await receiverChatRef.set({
        'chatId': widget.chatId,
        'isGroup': false,
        'participants': [currentUserId, receiverId],
        'lastMessage': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await receiverChatRef.update({
        'lastMessage': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Ajoutez le message à la collection Messages de l'utilisateur actuel
    await currentUserChatRef.collection('Messages').add({
      "sender_id": currentUserId,
      "receiver_id": receiverId,
      "text": messageText,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    // Ajoutez le message à la collection Messages du récepteur
    await receiverChatRef.collection('Messages').add({
      "sender_id": currentUserId,
      "receiver_id": receiverId,
      "text": messageText,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    messageController.clear();

  //DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
  // Récupérer le token FCM du destinataire
  //DocumentSnapshot receiverDoc = await FirebaseFirestore.instance.collection('Users').doc(receiverId).get(); 
  //String? token = receiverDoc['fcm_token'];

 /* if (token != null) {
    // ignore: deprecated_member_use
    await FirebaseMessaging.instance.sendMessage(
      to: token,
      data: {
        'title': 'Nouveau message de ${userDoc['nom']} ${userDoc['prenom']}',
        'body': messageText,
      },
    );
  } */

  }

  Future<void> _sendFile() async {
    if (selectedFile == null || currentUserId == null || receiverId == null) return;

    try {
      final fileName = selectedFile!.name;
      final fileBytes = selectedFile!.bytes;

      if (fileBytes == null) {
        throw Exception("File bytes are null. Ensure the file is selected properly.");
      }

      final storageRef = FirebaseStorage.instance.ref().child('chat_files/$fileName');
      final uploadTask = storageRef.putData(fileBytes);

      // Wait for the upload to complete
      final taskSnapshot = await uploadTask.whenComplete(() {});

      // Get the download URL after successful upload
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      final messageData = {
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'file_name': fileName,
        'file_url': downloadUrl,
      };

      // Save the message to Firestore for both sender and receiver
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .collection("UserChats")
          .doc(widget.chatId)
          .collection("Messages")
          .add(messageData);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(receiverId)
          .collection("UserChats")
          .doc(widget.chatId)
          .collection("Messages")
          .add(messageData);

      setState(() {
        selectedFile = null;
      });
    } catch (e) {
      // Handle errors during upload or Firestore operations
      print("Error during file upload or Firestore operation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoi du fichier : $e")),
      );
    }
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

  /// 📩 Envoyer une notification via FCM
Future<void> sendPushNotification(String token, String title, String body) async {
  const String serverKey =
      "YOUR_SERVER_KEY"; // 🔥 Mets ici ta clé serveur Firebase

  final response = await http.post(
    Uri.parse('https://fcm.googleapis.com/fcm/send'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    },
    body: jsonEncode({
      'to': token,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
    }),
  );

  if (response.statusCode == 200) {
    // ignore: avoid_print
    print("✅ Notification envoyée !");
  } else {
    // ignore: avoid_print
    print("❌ Erreur lors de l'envoi : ${response.body}");
  }
}
}


