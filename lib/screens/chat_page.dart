import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;

  const ChatPage({super.key, required this.receiverEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  String _getChatID(String user1, String user2) {
    List<String> emails = [user1, user2];
    emails.sort();
    return "${emails[0]}_${emails[1]}";
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && user != null) {
      String chatID = _getChatID(user!.email!, widget.receiverEmail);

      await _firestore.collection('chats').doc(chatID).set({
        'lastMessage': _messageController.text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('chats')
          .doc(chatID)
          .collection('messages')
          .add({
        'sender': user!.email,
        'receiver': widget.receiverEmail,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatID = _getChatID(user!.email!, widget.receiverEmail);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            widget.receiverEmail,
            style: GoogleFonts.poppins(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          )),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatID)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Start to chat"));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message =
                        messages[index].data() as Map<String, dynamic>;
                    bool isMe = message['sender'] == user!.email;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Color.fromARGB(255, 14, 190, 123)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? "",
                              style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : Color.fromARGB(255, 14, 190, 123)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              message['sender'],
                              style:
                                  TextStyle(fontSize: 10, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  //เปลี่ยนสีในฟิลให้รับค่าแล้วไม่เป็นสีเทาอ่อนๆ
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Enter...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        // ✅ เมื่อกดแล้วเปลี่ยนเป็นสีเขียว
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 14, 190, 123),
                            width: 2.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    cursorColor: Color.fromARGB(255, 14, 190, 123),
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send,
                      color: Color.fromARGB(255, 14, 190, 123)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
