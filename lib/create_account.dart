import 'dart:io';

import 'package:financefriend/location_card_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'profile_picture_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();

class CreateAccount extends StatelessWidget {
  final ApplicationState appState;

  CreateAccount({super.key, required this.appState});

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final List<String> goalChips = [];

  final String profileUrl =
      "https://firebasestorage.googleapis.com/v0/b/financefriend-41da9.appspot.com/o/profile_pictures%2Fdefault.png?alt=media&token=a0d5c338-c123-4373-9ece-d0b0ba40194a";
  Future<bool> doesKeyExist(String key) async {
    DataSnapshot snapshot;
    try {
      var event = await reference.child('userIndex').once();
      snapshot = event.snapshot;

      // Check if the key exists in the snapshot
      return (snapshot.value as Map<String, dynamic>?)?[key] != null;
    } catch (e) {
      print('Error fetching data: $e');
      return false;
    }
  }

  Future<void> _handleRegistration(BuildContext context) async {
    // Check if the desired name is unique
    final String desiredName = nameController.text.trim();
    bool exists = await doesKeyExist(desiredName);

    if (exists) {
      // If the name is not unique, show an alert to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Name Not Available'),
            content: const Text(
                'The provided name is already in use. Please choose a different name.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Continue with user registration
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      await user?.updateDisplayName(desiredName);
      await user?.reload();
      print(user);
      await user?.updatePhotoURL(profileUrl);

      final String uid = user!.uid;

      final usersReference = reference.child('users');

      final currentUserReference = usersReference.child(uid);
      await currentUserReference.set({
        'name': desiredName,
        'bio': bioController.text,
        'goals': goalChips,
        'landing_page': '/home',
        'profilePic': profileUrl,
      });

      await reference
          .child('userIndex')
          .child(desiredName)
          .set(currentUser!.uid);

      // Registration successful, navigate to another page or handle the next steps.
      Navigator.pushNamed(context, '/home');
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The provided email is already in use.'),
              ),
            );
            break;
          case 'weak-password':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'The password is too weak. Please choose a stronger password.'),
              ),
            );
            break;
          case 'invalid-email':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The provided email is not valid.'),
              ),
            );
            break;
          // Add more cases for other FirebaseAuthException codes if needed
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration failed. Please try again.'),
              ),
            );
        }
      } else {
        // Handle other non-FirebaseAuthException registration errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LoginAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CREATE ACCOUNT',
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
                    const SizedBox(height: 24.0),
                    Field(label: 'Email', controller: emailController),
                    Field(label: 'Password', controller: passwordController),
                    Field(
                        label: 'Confirm Password',
                        controller: confirmPasswordController),
                    Field(label: 'Name', controller: nameController),
                    Field(label: 'Bio', controller: bioController),
                    ProfilePictureUpload(profileUrl: profileUrl, dash: false),
                    GoalsList(goalChips: goalChips),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        _handleRegistration(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          fixedSize: const Size(120, 50)),
                      child: const Text('Join',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          )),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  const Field({super.key, required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 16.0),
      SizedBox(
        width: 300,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelText: label,
          ),
        ),
      ),
    ]);
  }
}

class GoalsList extends StatefulWidget {
  final List<String> goalChips;

  const GoalsList({super.key, required this.goalChips});

  @override
  _GoalsListState createState() => _GoalsListState();
}

class _GoalsListState extends State<GoalsList> {
  final TextEditingController controller = TextEditingController();

  void addGoalChip(String goal) {
    setState(() {
      widget.goalChips.add(goal);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: widget.goalChips
                .map(
                  (goal) => Chip(
                    label: Text(goal),
                    onDeleted: () {
                      setState(() {
                        widget.goalChips.remove(goal);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Add a Spending Goal',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final typedGoal = controller.text.trim();
                  if (typedGoal.isNotEmpty &&
                      !widget.goalChips.contains(typedGoal)) {
                    addGoalChip(typedGoal);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
