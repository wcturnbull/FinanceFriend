import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'home.dart';
import 'ff_appbar.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add a delay of 3 seconds before navigating to the landing page
    Timer(Duration(seconds: 3), () async {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return HomePage(); // Replace with your actual page widget
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            const duration =
                Duration(milliseconds: 1000); // Adjust the duration here

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            var opacityAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: opacityAnimation,
              child: child,
            );
          },
          transitionDuration:
              const Duration(milliseconds: 1000), // Adjust the duration here
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // You can add any loading animation or design here
    return Scaffold(
      backgroundColor: Colors.grey[800], // Dark grey background color
      appBar: FFAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use FutureBuilder for delayed appearance of the image
            FutureBuilder(
              future: Future.delayed(Duration(seconds: 1)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Image.asset(
                    'images/FFLogo.png',
                    width: 150, // Set your desired width
                    height: 150, // Set your desired height
                  );
                } else {
                  return Container(); // You can return a placeholder or loading indicator here
                }
              },
            ),
            Text(
              'Welcome To Finance Friend!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white, // White text color
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
