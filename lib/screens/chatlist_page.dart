import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  /// ✅ ฟังก์ชันเริ่มต้นแชทกับผู้ใช้ที่ค้นหา
  void _startChat(String searchQuery) async {
    if (searchQuery.isEmpty || searchQuery == user!.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("A valid email address must be entered")),
      );
      return;
    }

    // ✅ ค้นหาผู้ใช้โดยใช้ `email` หรือ `username`
    QuerySnapshot userDocs = await _firestore
        .collection('users')
        .where('username', isEqualTo: searchQuery)
        .get();

    String receiverEmail = "";

    if (userDocs.docs.isNotEmpty) {
      receiverEmail = userDocs.docs.first.get('email');
    } else {
      receiverEmail = searchQuery; // ถ้าไม่มี username ให้ใช้ email ที่กรอก
    }

    // ✅ สร้าง Chat ID โดยใช้ email ทั้งสอง
    List<String> emails = [user!.email!, receiverEmail];
    emails.sort(); // เรียงลำดับเพื่อป้องกันซ้ำ
    String chatID = "${emails[0]}_${emails[1]}";

    // ✅ ตรวจสอบว่าห้องแชทมีอยู่หรือไม่
    DocumentSnapshot chatDoc =
        await _firestore.collection('chats').doc(chatID).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatID).set({
        'lastMessage': "",
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    // ✅ เปิดหน้าแชท
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(receiverEmail: receiverEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Chat",
          style: GoogleFonts.poppins(
              color: Color.fromARGB(255, 14, 190, 123),
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Enter Email or Username...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 14, 190, 123),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    cursorColor: Colors.black,
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _startChat(_searchController.text.trim());
                  },
                  child: Text(
                    "Search",
                    style: GoogleFonts.poppins(
                      color: Color.fromARGB(255, 14, 190, 123),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text("Don't have any messages",
                    style: GoogleFonts.poppins(color: Colors.black)));
          }

          var chatList = snapshot.data!.docs.where((doc) {
            var chatID = doc.id.split("_");
            return chatID.contains(user!.email);
          }).toList();

          // 🔍 ค้นหาผู้ใช้ตาม email หรือ username
          var filteredChatList = chatList.where((doc) {
            var chatID = doc.id.split("_");
            var receiverEmail = chatID
                .firstWhere((email) => email != user!.email, orElse: () => "");

            return _searchQuery.isEmpty || receiverEmail.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: filteredChatList.length,
            itemBuilder: (context, index) {
              var chat = filteredChatList[index].data() as Map<String, dynamic>;
              var chatID = filteredChatList[index].id;
              var emails = chatID.split("_");
              var receiverEmail = emails.firstWhere(
                  (email) => email != user!.email,
                  orElse: () => "");

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(receiverEmail)
                    .get(), // 🔥 ดึงข้อมูล username
                builder: (context, userSnapshot) {
                  String username = receiverEmail; // ใช้ email เป็นค่าเริ่มต้น
                  if (userSnapshot.connectionState == ConnectionState.done &&
                      userSnapshot.hasData &&
                      userSnapshot.data!.exists) {
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    username = userData['username'] ?? receiverEmail;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor: Color.fromARGB(255, 14, 190, 123),
                    ),
                    title: Text(username,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            fontSize: 15)),
                    subtitle: Text(chat['lastMessage'] ?? "Start a chat!",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12)),
                    trailing: Text(
                      chat['lastTimestamp'] != null
                          ? (chat['lastTimestamp'] as Timestamp)
                              .toDate()
                              .toString()
                              .substring(0, 16)
                          : "",
                      style:
                          TextStyle(color: Color.fromARGB(255, 14, 190, 123)),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatPage(receiverEmail: receiverEmail),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
