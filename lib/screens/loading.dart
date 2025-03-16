import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_project/screens/home_page.dart';

class LoadingGohome extends StatefulWidget {
  const LoadingGohome({super.key});

  @override
  State<LoadingGohome> createState() => _LoadingGohomeState();
}

class _LoadingGohomeState extends State<LoadingGohome> {
  @override
  void initState() {
    super.initState();
    // ตั้งเวลาให้โหลด 5 วินาทีแล้วเปลี่ยนหน้าไปยัง HomeScreen()
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen()), // เปลี่ยนไปยัง HomeScreen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LottieBuilder.network(
          'https://lottie.host/c46fdf42-b028-46e2-872f-386eff498bb9/06TDzj8zLm.json',
        ),
      ),
    );
  }
}
