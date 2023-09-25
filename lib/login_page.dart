import 'package:flutter/material.dart';
import 'ff_appbar.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FFAppBar(),
      body: Center(
        child: Container(
          width: 500, // Adjust the width as needed
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary,
            borderRadius: BorderRadius.circular(10.0), // Add rounded corners
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SIGN IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set the text color to white
                ),
              ),
              const SizedBox(height: 20.0), // Add spacing between the text and text fields
              const TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white, // Set text field background color border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
              ),
              const SizedBox(height: 16.0), // Add spacing between text fields
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white, // Set text field background color
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 16.0), // Add spacing below text fields
              ElevatedButton(
                onPressed: () {
                  // Perform login logic here
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
