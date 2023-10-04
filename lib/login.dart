import 'package:flutter/material.dart';
import 'ff_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';

class Login extends StatelessWidget {
  final ApplicationState appState;

  Login({required this.appState, super.key});

  final TextEditingController emailControl = TextEditingController();
  final TextEditingController passwordControl = TextEditingController();

  Future<void> _handleLogin(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailControl.text.trim(),
        password: passwordControl.text.trim(),
      );
      appState.init(); // Initialize the app state to trigger userChanges()
      Navigator.pushNamed(context, '/home');
    } catch (e) {
      // Handle authentication errors (e.g., invalid credentials)
      print('Authentication error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed. Please check your credentials.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FFAppBar(),
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
