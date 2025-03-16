import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screens/main_page.dart';
import 'package:flutter_project/screens/password_page.dart';
import 'package:flutter_project/screens/signup_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // ตรวจสอบว่าล็อกอินสำเร็จหรือไม่
      if (userCredential.user != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(60, 100, 60, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                "assets/images/w-logo-app.png",
                height: 200,
                width: 200,
              ),
              SizedBox(height: 60),
              SizedBox(
                width: 350,
                child: ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: Image.asset(
                    "assets/images/google-icon.png",
                    height: 20,
                    width: 20,
                  ),
                  label: Text(
                    "Sign in with Google ",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "or",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        autofocus: true,
                        decoration: InputDecoration(
                          icon: Icon(Icons.mail, color: Colors.black),
                          labelText: 'Email',
                          labelStyle: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w300),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                        ),
                        cursorColor: Colors.grey,
                        style: GoogleFonts.poppins(
                            color: Color.fromARGB(255, 14, 190, 123)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 350,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    passwordpage(email: emailController.text)),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(color: Colors.white, width: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: SizedBox(width: double.infinity, height: 20),
                    ),
                    Positioned(
                      child: Text(
                        "Next",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 70),
              SizedBox(
                width: 350,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // การทำงานเมื่อกด "Sign up"
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return registPage();
                        }));
                      },
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 14, 190, 123),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
