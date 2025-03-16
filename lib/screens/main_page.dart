import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter_project/screens/chatlist_page.dart';
import 'package:flutter_project/screens/profile_page.dart';
import 'package:flutter_project/screens/search_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  /// ✅ ฟังก์ชันดึงข้อมูลผู้ใช้จาก Firestore
  Future<Map<String, dynamic>> getUserData(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      return userSnapshot.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> updateProfile(String newUsername, String newPhotoURL) async {
    if (user == null) return;

    try {
      // ✅ อัปเดตข้อมูลใน Firestore collection `users`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'username': newUsername,
        'photoURL': newPhotoURL,
      });

      // ✅ อัปเดตทุกโพสต์ที่เคยโพสต์โดยผู้ใช้
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user!.uid)
          .get();

      for (var doc in postsSnapshot.docs) {
        await doc.reference.update({
          'username': newUsername,
          'photoURL': newPhotoURL,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile. Try again.")),
      );
    }
  }

  Future<void> _postMessage(BuildContext context) async {
    final TextEditingController _postController = TextEditingController();
    final TextEditingController _imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Create a Post",
              style: GoogleFonts.poppins(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _postController,
                decoration: InputDecoration(
                  labelText: "Enter your post...",
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 14, 190, 123))),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                cursorColor: Color.fromARGB(255, 14, 190, 123),
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: "Image URL...",
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 14, 190, 123))),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                cursorColor: Color.fromARGB(255, 14, 190, 123),
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel",
                  style: GoogleFonts.poppins(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                if (_postController.text.trim().isNotEmpty && user != null) {
                  // ✅ ดึงข้อมูลโปรไฟล์ผู้ใช้จาก Firestore
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .get();

                  String username = userDoc['username'] ?? "Unknown";
                  String photoURL = userDoc['photoURL'] ??
                      "https://via.placeholder.com/150"; // รูป default
                  String email =
                      user!.email ?? "Unknown Email"; // ✅ เพิ่ม email

                  // ✅ เพิ่มข้อมูล `email` ลงในโพสต์
                  await FirebaseFirestore.instance.collection('posts').add({
                    'userId': user?.uid ?? "Unknown",
                    'username': username,
                    'email': email, // ✅ บันทึก email ของผู้โพสต์
                    'photoURL': photoURL,
                    'message': _postController.text.trim(),
                    'imageUrl': _imageUrlController.text.trim().isNotEmpty
                        ? _imageUrlController.text.trim()
                        : null,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post success!')),
                  );

                  Navigator.pop(context);
                }
              },
              child: Text("Post",
                  style: GoogleFonts.poppins(
                      color: Color.fromARGB(255, 14, 190, 123))),
            ),
          ],
        );
      },
    );
  }

  /// ✅ ฟังก์ชันจัดการรีโพสต์ (Repost/Unrepost)
  Future<void> repost(String postID, Map<String, dynamic> postData) async {
    if (user == null) return;

    DocumentReference repostRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('reposts')
        .doc(postID);

    DocumentSnapshot repostSnapshot = await repostRef.get();

    if (repostSnapshot.exists) {
      // ✅ ลบรีโพสต์ (Unrepost)
      await repostRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Repost canceled")),
      );
    } else {
      // ✅ ดึงข้อมูล `username` และ `photoURL` ของเจ้าของโพสต์จาก Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postData['userId'])
          .get();

      String originalUsername = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['username'] ??
              "Unknown User"
          : "Unknown User";

      String originalPhotoURL = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['photoURL'] ??
              "https://via.placeholder.com/150"
          : "https://via.placeholder.com/150";

      // ✅ เพิ่มข้อมูล `username` และ `photoURL` ลงใน Repost
      await repostRef.set({
        'originalPostID': postID,
        'userId': postData['userId'],
        'username': originalUsername, // 🔥 บันทึกชื่อของเจ้าของโพสต์
        'photoURL': originalPhotoURL, // 🔥 บันทึกรูปของเจ้าของโพสต์
        'message': postData['message'],
        'imageUrl': postData['imageUrl'] ?? "",
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Repost success!")),
      );
    }
  }

  /// ✅ ตรวจสอบว่าโพสต์นี้ถูกรีโพสต์ไปแล้วหรือไม่
  Future<bool> isReposted(String postID) async {
    if (user == null) return false;

    DocumentSnapshot repostSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('reposts')
        .doc(postID)
        .get();

    return repostSnapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Image.asset(
          "assets/images/w-logo-app.png",
          height: 40,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final posts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var postData = posts[index].data() as Map<String, dynamic>;
                String userId = postData['userId'];

                // ✅ ดึงค่า timestamp และแปลงเป็น DateTime
                Timestamp? timestamp = postData['timestamp'];
                DateTime? postTime = timestamp?.toDate();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return SizedBox(); // แสดงตัวโหลดระหว่างดึงข้อมูล
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return SizedBox(); // ถ้าข้อมูลผู้ใช้ไม่มี ไม่ต้องแสดงโพสต์
                    }

                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    String username = userData['username'] ?? "Unknown User";
                    String photoURL = userData['photoURL'] ??
                        "https://via.placeholder.com/150";

                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!, // ✅ สีของเส้นคั่น
                                width: 1.5, // ✅ ปรับความหนาของเส้น
                              ),
                            ),
                          ),
                          child: Card(
                            color: Colors.white,
                            margin:
                                EdgeInsets.all(0), // ✅ เอาช่องว่างของ Card ออก
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(0), // ✅ เอามุมโค้งออก
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 🔹 แสดงโปรไฟล์ของผู้โพสต์
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(photoURL),
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600]),
                                          ),
                                          Text(
                                            userData['email'] ?? "No Email",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Spacer(),

                                      // ✅ แสดง timestamp ถ้าไม่เป็น null
                                      if (postTime != null)
                                        Text(
                                          DateFormat('dd MMM yyyy, HH:mm')
                                              .format(postTime),
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                  SizedBox(height: 10),

                                  /// 🔹 แสดงรูปภาพในโพสต์ (ถ้ามี)
                                  if (postData['imageUrl'] != null &&
                                      postData['imageUrl'].isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        postData['imageUrl'],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  SizedBox(height: 10),

                                  /// 🔹 แสดงข้อความโพสต์
                                  Text(
                                    postData['message'] ?? "No message",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]),
                                  ),

                                  /// ✅ ปุ่มรีโพสต์
                                  FutureBuilder<bool>(
                                    future: isReposted(posts[index].id),
                                    builder: (context, snapshot) {
                                      bool isReposted = snapshot.data ?? false;

                                      return Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              repost(posts[index].id, postData),
                                          icon: Icon(
                                            Icons.repeat,
                                            color: isReposted
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          label: Text(
                                            isReposted ? "Unrepost" : "Repost",
                                            style: GoogleFonts.poppins(
                                              color: isReposted
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isReposted
                                                ? Color.fromARGB(
                                                    255, 14, 190, 123)
                                                : Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }
          return Center(child: Text('No posts yet.'));
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _postMessage(context);
        },
        backgroundColor:
            Color.fromARGB(255, 14, 190, 123), // ✅ เปลี่ยนสีพื้นหลัง
        elevation: 5, // ✅ เพิ่มเงาให้ปุ่มดูโดดเด่น
        shape: CircleBorder(), // ✅ รูปทรงกลม
        child: Icon(
          Icons.add, // ✅ ไอคอนเพิ่มโพสต์
          size: 30, // ✅ ขนาดไอคอน
          color: Colors.white, // ✅ สีไอคอน
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endDocked, // ✅ จัดตำแหน่งให้ลอยขวาล่าง

      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        showElevation: true,
        animationCurve: Curves.easeInOut,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MainScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => SearchPage()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ChatListPage()));
          } else if (index == 3) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => YourProfile()));
          }
        },
        items: [
          FlashyTabBarItem(
            icon: Icon(Icons.home, color: Colors.black), // เปลี่ยนสีไอคอน
            title: Text('Home',
                style: TextStyle(
                    color:
                        Color.fromARGB(255, 14, 190, 123))), // เปลี่ยนสีข้อความ
            activeColor:
                const Color.fromARGB(255, 14, 190, 123), // สีไอคอนที่ถูกเลือก
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.search, color: Colors.black),
            title: Text('Search', style: TextStyle(color: Colors.black)),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.chat, color: Colors.black),
            title: Text('Chat', style: TextStyle(color: Colors.black)),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            title: Text('Profile', style: TextStyle(color: Colors.black)),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
        ],
      ),
    );
  }
}
