import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/screens/main_page.dart';
import 'package:flutter_project/screens/resetpassword_page.dart';
import 'package:google_fonts/google_fonts.dart';

class passwordpage extends StatefulWidget {
  final String email;

  const passwordpage({super.key, required this.email});

  @override
  State<passwordpage> createState() => _passwordpageState();
}

class _passwordpageState extends State<passwordpage> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  bool _isObscure = true;
  final FirebaseAuth _auth = FirebaseAuth.instance; // เชื่อม Firebase Auth

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // ตรวจสอบอีเมลและรหัสผ่านกับ Firebase
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: widget.email,
          password: passwordController.text,
        );

        // ถ้าสำเร็จ เปลี่ยนหน้าไป MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );

        print("Login Successful: ${userCredential.user?.email}");
      } catch (e) {
        // ถ้า Login ไม่ผ่าน ให้แสดงข้อความแจ้งเตือน
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false, // แก้ให้ไม่เกิด overflow
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 50, 30, 0),
        child: Column(
          children: [
            Image.asset(
              "assets/images/w-logo-app.png",
              height: 100,
              width: 100,
            ),
            SizedBox(height: 60),
            Container(
              width: 350, //กำหนดความกว้างตายตัวเพื่อไม่ให้ข้อความขยายออกไป
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.email, color: Colors.black),
                  SizedBox(width: 20), //เพิ่มระยะห่างระหว่างไอคอนกับข้อความ
                  Expanded(
                    // ป้องกันข้อความล้นและรองรับการตัดคำ
                    child: Text(
                      widget.email,
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis, //ถ้าข้อความยาวเกินจะตัดเป็น "..."
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Please enter your password ',
              style: GoogleFonts.poppins(
                color: Color.fromARGB(255, 14, 190, 123),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock, color: Colors.black),
                        labelStyle: TextStyle(color: Colors.black),
                        label: Text(
                          "Password",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(0, 255, 255, 255),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      cursorColor: Colors.grey,
                      style: GoogleFonts.poppins(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // ปุ่ม Login
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: _login, // เรียกใช้ฟังก์ชัน Login
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: BorderSide(
                      color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                  padding: EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 20),

            // ปุ่ม Forgot Password
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => resetPasswordPage(),
                    ),
                  );
                },
                child: Text(
                  "Forgot Password?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 14, 190, 123),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
