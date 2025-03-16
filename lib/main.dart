import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screens/loading.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whispr', // ตั้งชื่อแอป
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 255, 255, 255), // กำหนดสีหลัก
        scaffoldBackgroundColor:
            const Color.fromARGB(221, 0, 0, 0), // สีพื้นหลัง
      ),
      home: LoadingGohome(),
    );
  }
}
