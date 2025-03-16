import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class resetPasswordPage extends StatefulWidget {
  const resetPasswordPage({super.key});

  @override
  State<resetPasswordPage> createState() => _resetPasswordPageState();
}

class _resetPasswordPageState extends State<resetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  // ฟังก์ชันรีเซ็ตรหัสผ่าน
  Future<void> passwordReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: emailController.text);

        // แสดง SnackBar แจ้งเตือนเมื่อส่งอีเมลสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password reset link sent! Check your email.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
          ),
        );

        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        // ถ้าเกิดข้อผิดพลาด ให้แสดงข้อความที่ได้รับจาก Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? "Something went wrong. Try again!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
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
      body: Container(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Find your whips account',
                textAlign: TextAlign.start,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ),
              Text(
                'Enter your email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              Text(
                'to get a password reset link',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        //ขอบเริ่มต้น
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        //เมื่อกดแล้วเปลี่ยนเป็นสีเขียว
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 14, 190, 123),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.mail, color: Colors.black),
                      labelText: "Email",
                      labelStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w200,
                          color: Colors.black),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    ),
                    cursorColor: Colors.grey,
                    style: GoogleFonts.poppins(
                      color: Color.fromARGB(255, 14, 190, 123),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
              ElevatedButton(
                onPressed: passwordReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(150, 60),
                ),
                child: Text(
                  'Reset Password',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
