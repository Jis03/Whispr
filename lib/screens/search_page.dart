import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screens/chatlist_page.dart';
import 'package:flutter_project/screens/main_page.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter_project/screens/profile_page.dart';
// import 'package:flutter_project/screens/real_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          onChanged: (query) {
            setState(() {
              _searchQuery = query.trim();
            });
          },
          decoration: InputDecoration(
            hintText: "Search by email, message, or image URL...",
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = "";
              });
            },
          ),
        ],
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
            final posts = snapshot.data!.docs.where((post) {
              var postData = post.data() as Map<String, dynamic>;

              // 🔹 ดึงค่าที่ต้องใช้ค้นหา
              String username = postData.containsKey('username') &&
                      postData['username'] != null
                  ? postData['username'].toLowerCase()
                  : "";
              String email =
                  postData.containsKey('email') && postData['email'] != null
                      ? postData['email'].toLowerCase()
                      : "";
              String message =
                  postData.containsKey('message') && postData['message'] != null
                      ? postData['message'].toLowerCase()
                      : "";
              String imageUrl = postData.containsKey('imageUrl') &&
                      postData['imageUrl'] != null
                  ? postData['imageUrl'].toLowerCase()
                  : "";

              // 🔎 ค้นหาจาก username, email, message, หรือ imageUrl
              return _searchQuery.isEmpty ||
                  username.contains(_searchQuery.toLowerCase()) ||
                  email.contains(_searchQuery.toLowerCase()) ||
                  message.contains(_searchQuery.toLowerCase()) ||
                  imageUrl.contains(_searchQuery.toLowerCase());
            }).toList();

            if (posts.isEmpty) {
              return Center(child: Text("No results found."));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var post = posts[index].data() as Map<String, dynamic>;

                return Column(
                  children: [
                    Card(
                      color: Colors.white,
                      margin: EdgeInsets.all(0),
                      elevation: 0, // ✅ ปิดเงาของ Card ป้องกันเส้นซ้อน
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0)),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🔹 แสดงโปรไฟล์ของผู้โพสต์
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: post
                                              .containsKey('photoURL') &&
                                          post['photoURL'] != null &&
                                          post['photoURL'].isNotEmpty
                                      ? NetworkImage(post['photoURL'])
                                      : AssetImage(
                                              "assets/images/default_profile.png")
                                          as ImageProvider,
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['username'] ?? "Unknown User",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700]),
                                    ),
                                    Text(
                                      post['email'] ?? "Unknown Email",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            /// 🔹 แสดงรูปภาพในโพสต์ (ถ้ามี)
                            if (post.containsKey('imageUrl') &&
                                post['imageUrl'] != null &&
                                post['imageUrl'].isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  post['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text("รูปภาพไม่สามารถโหลดได้"),
                                ),
                              ),
                            SizedBox(height: 10),

                            /// 🔹 แสดงข้อความโพสต์
                            Text(
                              post['message'] ?? "No message",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < posts.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(
                          thickness: 0,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                );
              },
            );
          }
          return Center(child: Text("No posts available."));
        },
      ),
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
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatListPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => YourProfile()),
            );
          }
        },
        items: [
          FlashyTabBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            title: Text('Home',
                style: TextStyle(color: Color.fromARGB(255, 14, 190, 123))),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.search, color: Colors.black),
            title: Text('Search',
                style: TextStyle(color: Color.fromARGB(255, 14, 190, 123))),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.chat, color: Colors.black),
            title: Text('Chat',
                style: TextStyle(color: Color.fromARGB(255, 14, 190, 123))),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            title: Text('Profile',
                style: TextStyle(color: Color.fromARGB(255, 14, 190, 123))),
            activeColor: const Color.fromARGB(255, 14, 190, 123),
          ),
        ],
      ),
    );
  }
}
