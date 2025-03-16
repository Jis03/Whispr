import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _photoURLController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ โหลดข้อมูลจาก Firestore และแสดงใน TextField
  Future<void> _loadUserData() async {
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      _usernameController.text =
          userData?['username'] ?? user!.displayName ?? "";
      _photoURLController.text = userData?['photoURL'] ?? user!.photoURL ?? "";
    }
  }

  /// ✅ อัปเดตโปรไฟล์ลง Firestore และ Firebase Auth
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': user!.email,
        'photoURL': _photoURLController.text.trim(),
      }, SetOptions(merge: true));

      await user!.updateDisplayName(_usernameController.text.trim());
      await user!.updatePhotoURL(_photoURLController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile Updated Successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Edit Profile",
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 14, 190, 123)),
          )),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔹 รูปโปรไฟล์ (Preview)
              CircleAvatar(
                backgroundColor: Color.fromARGB(255, 14, 190, 123),
                radius: 50,
                backgroundImage: _photoURLController.text.isNotEmpty
                    ? NetworkImage(_photoURLController.text)
                    : AssetImage("assets/images/default_profile.png")
                        as ImageProvider,
              ),
              SizedBox(height: 80),

              /// 🔹 ป้อน URL รูปภาพ
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft, // ✅ จัดให้ชิดซ้าย
                    child: Text(
                      "You can upload your profile picture here",
                      style: GoogleFonts.poppins(
                        color: Color.fromARGB(255, 14, 190, 123),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft, // ✅ จัดให้ชิดซ้าย
                    child: Text(
                      "Must be uploaded as a url only",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              TextFormField(
                controller: _photoURLController,
                decoration: InputDecoration(
                  labelText: "Profile Image URL",
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 14, 190, 123))),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                cursorColor: Color.fromARGB(
                    255, 14, 190, 123), // ✅ เปลี่ยนสีเคอร์เซอร์เป็นเขียว
                style: TextStyle(color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an image URL";
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // อัปเดต Preview ทันทีเมื่อเปลี่ยน
                },
              ),
              SizedBox(height: 30),
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft, // ✅ จัดให้ชิดซ้าย
                    child: Text(
                      "You can change your username here",
                      style: GoogleFonts.poppins(
                        color: Color.fromARGB(255, 14, 190, 123),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft, // ✅ จัดให้ชิดซ้าย
                    child: Text(
                      "You should name it politely.",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              /// 🔹 ป้อนชื่อผู้ใช้
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 14, 190, 123))),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                cursorColor: Color.fromARGB(
                    255, 14, 190, 123), // ✅ เปลี่ยนสีเคอร์เซอร์เป็นเขียว
                style: TextStyle(
                    color: Colors.grey), // ✅ เปลี่ยนสีตัวหนังสือเมื่อพิมพ์
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Username cannot be empty";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              /// 🔹 ปุ่มบันทึกข้อมูล
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Color.fromARGB(255, 14, 190, 123),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
