import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login.dart';

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
      Navigator.pushNamed(context, await _getLandingPage());
    });
  }

  @override
  Widget build(BuildContext context) {
    // You can add any loading animation or design here
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Test Screen', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<String> _getLandingPage() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    if (!user.hasChild('landing_page')) {
      return '/home';
    } else {
      DataSnapshot snapshot = await userRef.child('landing_page').get();
      String landingPage = snapshot.value as String;
      return landingPage;
    }
  }
}
