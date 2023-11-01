import 'package:financefriend/profile.dart';
import 'package:flutter/material.dart';
import 'login_appbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class Login extends StatelessWidget {
  final ApplicationState appState;

  Login({required this.appState, super.key});

  final TextEditingController emailControl = TextEditingController();
  final TextEditingController passwordControl = TextEditingController();

  Future<String> _getLandingPage() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    if(!user.hasChild('landing_page')) {
      return '/home';
    } else {
      DataSnapshot snapshot = await userRef.child('landing_page').get();
      String landingPage = snapshot.value as String;
      return landingPage;
    }
  }

  void _resetPassword(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailControl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Reset email sent successfully!'),
        ),
      );
    } catch (e) {
      print('Password reset error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Password reset failed. Please verify that your email was entered correctly.'),
        ),
      );
    }
  }

  void _openPasswordResetter(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Stack(children: <Widget>[
          Positioned(
            right: -40,
            top: -40,
            child: InkResponse(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
              ),
            ),
          ),
          Form(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Password Reset',
                        textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                    )),
                    const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                            'Enter your email',
                            style: TextStyle(fontSize: 20)
                    )),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: TextField(
                          controller: emailControl,
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            child: const Text('Submit'),
                            onPressed: () {
                              _resetPassword(context);
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                    )),
              ]))
        ]),
      ));
  }

  Future<void> _handleLogin(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailControl.text.trim(),
        password: passwordControl.text.trim(),
      );
      appState.init(); // Initialize the app state to trigger userChanges()
      Navigator.pushNamed(context, await _getLandingPage());
    } catch (e) {
      // Handle authentication errors (e.g., invalid credentials)
      print('Authentication error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Authentication failed. Please check your credentials.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LoginAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SIGN IN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48,
                color: Colors.black,
              ),
            ),
            Container(
              width: 400, // Adjust the width as needed
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40.0),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: emailControl,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: passwordControl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Password',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _handleLogin(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        fixedSize: const Size(120, 50)),
                    child: const Text('Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        )),
                  ),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/create_account");
                    },
                    child: const Text(
                        "New here? Click here to create an account!",
                        style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white)),
                  ),
                  GestureDetector(
                    onTap: () {
                      _openPasswordResetter(context);
                    },
                    child: const Text(
                        "Forgot your password? Click here to reset it!",
                        style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white)),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
