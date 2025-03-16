import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/chatlist_page.dart';
import 'package:flutter_project/screens/main_page.dart';
import 'package:flutter_project/screens/search_page.dart';
import 'package:flutter_project/screens/editprofile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/screens/home_page.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';

class YourProfile extends StatefulWidget {
  const YourProfile({super.key});

  @override
  State<YourProfile> createState() => _YourProfileState();
}

class _YourProfileState extends State<YourProfile> {
  User? user;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
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
          .where('userId', isEqualTo: user!.uid) // คีย์ต้องตรงกับ Firestore
          .get();

      for (var doc in postsSnapshot.docs) {
        await doc.reference.update({
          'username': newUsername,
          'photoURL': newPhotoURL,
        });
      }

      // ✅ รีเฟรช UI หลังจากอัปเดตสำเร็จ
      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

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
      // ✅ บันทึกเฉพาะ `originalPostID` เพื่อให้สามารถดึงข้อมูลอัปเดตจาก `posts` ได้
      await repostRef.set({
        'originalPostID': postID,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Repost success")),
      );
    }
  }

  void editPost(String docId, String currentMessage, String? currentImageUrl) {
    final TextEditingController _editMessageController =
        TextEditingController(text: currentMessage);
    final TextEditingController _editImageController =
        TextEditingController(text: currentImageUrl ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Edit Post",
              style: GoogleFonts.poppins(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editMessageController,
                decoration: InputDecoration(
                  labelText: "Edit your post...",
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
                controller: _editImageController,
                decoration: InputDecoration(
                  labelText: "Edit Image URL...",
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
                if (_editMessageController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(docId)
                      .update({
                    'message': _editMessageController.text.trim(),
                    'imageUrl': _editImageController.text.trim().isNotEmpty
                        ? _editImageController.text.trim()
                        : null,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Post edit success")),
                  );

                  Navigator.pop(context);
                }
              },
              child: Text("Save",
                  style: GoogleFonts.poppins(
                      color: Color.fromARGB(255, 14, 190, 123))),
            ),
          ],
        );
      },
    );
  }

  void deletePost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete success")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Can't delete : $e")),
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
                if (_postController.text.trim().isNotEmpty) {
                  try {
                    // ✅ ดึงข้อมูล `username` และ `photoURL` จาก Firestore
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .get();

                    String username = userDoc.exists && userDoc.data() != null
                        ? (userDoc.data()
                                as Map<String, dynamic>)['username'] ??
                            "Unknown User"
                        : "Unknown User";

                    String photoURL = userDoc.exists && userDoc.data() != null
                        ? (userDoc.data()
                                as Map<String, dynamic>)['photoURL'] ??
                            "https://via.placeholder.com/150"
                        : "https://via.placeholder.com/150";

                    // ✅ บันทึกข้อมูลโพสต์ลง Firestore
                    await FirebaseFirestore.instance.collection('posts').add({
                      'userId': user?.uid,
                      'username': username,
                      'photoURL': photoURL,
                      'message': _postController.text.trim(),
                      'imageUrl': _imageUrlController.text.trim().isNotEmpty
                          ? _imageUrlController.text.trim()
                          : null,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post success')),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Try again')),
                    );
                    print("Error posting message: $e");
                  }
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

  Future<Map<String, String>> getUserData() async {
    if (user == null) return {"username": "Unknown", "email": "Unknown"};

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    String username = userDoc.exists && userDoc.data() != null
        ? (userDoc.data() as Map<String, dynamic>)['username'] ?? "Unknown"
        : "Unknown";

    return {"username": username, "email": user?.email ?? "Unknown"};
  }

  // ✅ ฟังก์ชันออกจากระบบ
  void signUserOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text("Profile",
            style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 14, 190, 123),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              signUserOut(context);
            },
            icon: Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ แสดงข้อมูลโปรไฟล์
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color.fromARGB(255, 14, 190, 123),
                  radius: 40,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : AssetImage("assets/images/default_profile.png")
                          as ImageProvider,
                ),
                SizedBox(width: 15),
                FutureBuilder<Map<String, String>>(
                  future: getUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading...",
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black));
                    }

                    String username = snapshot.data?['username'] ?? "Unknown";
                    String email = snapshot.data?['email'] ?? "Unknown";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                        SizedBox(height: 5),
                        Text(email,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[500])),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 0, 0, 0),
                  child: IconButton(
                    icon: Icon(Icons.edit,
                        color: const Color.fromARGB(255, 14, 190, 123)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfilePage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text("Your Post",
                style: GoogleFonts.poppins(
                    color: Color.fromARGB(255, 14, 190, 123),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            // ✅ แสดงโพสต์ของผู้ใช้
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId',
                        isEqualTo: user?.uid ?? "") // เช็คให้ตรงกับ Firestore
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text("You haven't posted anything yet."));
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var postData =
                          posts[index].data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(); // รอโหลดข้อมูล
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return SizedBox(); // ไม่มีข้อมูลผู้ใช้
                          }

                          var userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          String username =
                              userData['username'] ?? "Unknown User";
                          String photoURL = userData['photoURL'] ??
                              "https://via.placeholder.com/150";

                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.all(10),
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 🔹 แสดงโปรไฟล์ของผู้โพสต์
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage:
                                                NetworkImage(photoURL),
                                          ),
                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                username,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      /// 🔹 ปุ่ม Edit และ Delete (Popup Menu)
                                      PopupMenuButton<String>(
                                        color: Colors.white,
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.grey[700]),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            editPost(
                                                posts[index].id,
                                                postData['message'],
                                                postData['imageUrl']);
                                          } else if (value == 'delete') {
                                            deletePost(posts[index].id);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit,
                                                    color: Colors
                                                        .greenAccent[700]),
                                                SizedBox(width: 8),
                                                Text("Edit"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color:
                                                        Colors.redAccent[400]),
                                                SizedBox(width: 8),
                                                Text("Delete"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 10),
            Text("Repost",
                style: GoogleFonts.poppins(
                    color: Color.fromARGB(255, 14, 190, 123),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            // ✅ แสดงโพสต์ที่รีโพสต์
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('reposts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text("You haven't reposted any posts yet",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.normal)));
                  }

                  final reposts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reposts.length,
                    itemBuilder: (context, index) {
                      var repostData =
                          reposts[index].data() as Map<String, dynamic>;
                      String originalPostID = repostData['originalPostID'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(originalPostID)
                            .get(),
                        builder: (context, postSnapshot) {
                          if (postSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!postSnapshot.hasData ||
                              !postSnapshot.data!.exists) {
                            return SizedBox(); // ถ้าโพสต์ต้นฉบับถูกลบ ไม่ต้องแสดง
                          }

                          var originalPostData =
                              postSnapshot.data!.data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            color: Colors.white, // ตั้งสีพื้นหลังให้เหมาะกับธีม
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 🔹 แสดงโปรไฟล์ของเจ้าของโพสต์ต้นฉบับ
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: originalPostData[
                                                        'photoURL'] !=
                                                    null &&
                                                originalPostData['photoURL']
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                originalPostData['photoURL'])
                                            : AssetImage(
                                                    "assets/images/default_profile.png")
                                                as ImageProvider,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        originalPostData['username'] ??
                                            "Unknown User",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[
                                              500], // ให้เข้ากับ Dark Mode
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 10),

                                  /// 🔹 แสดงเนื้อหาโพสต์
                                  Text(
                                    originalPostData['message'] ?? "No message",
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey[700]),
                                  ),
                                  SizedBox(height: 10),

                                  /// 🔹 แสดงรูปโพสต์ (ถ้ามี)
                                  if (originalPostData['imageUrl'] != null &&
                                      originalPostData['imageUrl'].isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        originalPostData['imageUrl'],
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Text("Unable to load images",
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.black)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ✅ Bottom Navigation Bar (Navbar เดิม)
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
          }
          if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => SearchPage()));
          }
          if (index == 2) {
            _postMessage(context);
          }
          if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ChatListPage()));
          }
          if (index == 4) {
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
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.search, color: Colors.black),
            title: Text('Search', style: TextStyle(color: Colors.black)),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.create, color: Colors.black),
            title: Text('Create', style: TextStyle(color: Colors.black)),
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
