import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class registPage extends StatefulWidget {
  const registPage({super.key});

  @override
  State<registPage> createState() => _registPageState();
}

class _registPageState extends State<registPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ✅ ฟังก์ชันสำหรับสมัครสมาชิกและบันทึกข้อมูล
  void signUserUp() async {
    // ✅ แสดง Dialog โหลด
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // ✅ ตรวจสอบรหัสผ่านว่าตรงกันหรือไม่
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            "Password don't match",
            style: GoogleFonts.poppins(fontSize: 16),
          )),
        );
        return;
      }

      // ✅ สมัครสมาชิกกับ Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ บันทึกข้อมูล `username` ลง Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // ปิด Dialog

      // ✅ แจ้งเตือนว่าสมัครสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'Membership registration successful',
          style: GoogleFonts.poppins(fontSize: 16),
        )),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // ปิด Dialog ถ้าเกิด Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          e.message ?? 'An error occurred',
          style: GoogleFonts.poppins(fontSize: 14),
        )),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unknown error occurred',
                style: GoogleFonts.poppins(fontSize: 14))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30),
              Center(
                child: Text(
                  'Create account',
                  style: GoogleFonts.poppins(
                      fontSize: 30, fontWeight: FontWeight.bold , color: Color.fromARGB(255, 14, 190, 123)),
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ ฟิลด์กรอก Username
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
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
                        labelText: "Username",
                        labelStyle: TextStyle(
                            color: Colors
                                .black), // ✅ ทำให้ Label เป็นสีเขียวเมื่อ Focus
                      ),
                      cursorColor: Color.fromARGB(255, 14, 190, 123),
                      style: GoogleFonts.poppins(
                            color: Colors.grey[600]),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),

                    // ✅ ฟิลด์กรอก Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 14, 190, 123),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: "Email",
                          labelStyle: TextStyle(color: Colors.black)),
                      cursorColor: Color.fromARGB(255, 14, 190, 123),
                      style: GoogleFonts.poppins(
                            color: Colors.grey[600]),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    // ✅ ฟิลด์กรอก Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 14, 190, 123),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.black)),
                      cursorColor: Color.fromARGB(255, 14, 190, 123),
                      style: GoogleFonts.poppins(
                            color: Colors.grey[600]),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),

                    // ✅ ฟิลด์กรอก Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 14, 190, 123),
                                width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: "Confirm Password",
                          labelStyle: TextStyle(color: Colors.black)),
                      cursorColor: Color.fromARGB(255, 14, 190, 123),
                      style: GoogleFonts.poppins(
                            color: Colors.grey[600]),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm the password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // ✅ ปุ่ม Sign Up
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            signUserUp();
                          }
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color.fromARGB(255, 14, 190, 123),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
