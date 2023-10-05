import 'package:financefriend/ff_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'profile_picture_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    final url = currentUser?.photoURL as String;

    return Scaffold(
        appBar: const FFAppBar(),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 600,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfilePictureUpload(profileUrl: url),
                      Text('${currentUser!.displayName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              color: Colors.white))
                    ],
                  ),
                  const Field(label: 'Bio'),
                  const Field(label: 'Email'),
                  const Field(label: 'Password'),
                  const SizedBox(height: 16.0)
                ],
              ),
            ),
          ],
        )));
  }
}

class Field extends StatefulWidget {
  const Field({super.key, required this.label});

  final String label;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late TextEditingController controller;
  String currentText = '';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    if (widget.label == 'Bio') {
      reference
          .child('users/${currentUser?.uid}/bio')
          .onValue
          .listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null) {
          setState(() {
            currentText = data.toString();
            controller.text = currentText;
          });
        }
      });
    } else if (widget.label == 'Email') {
      setState(() {
        currentText = currentUser!.email!;
        controller.text = currentText;
      });
    } else {
      setState(() {
        controller.text = currentText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 10.0),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Enter new ${widget.label}',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.update),
                  onPressed: () async {
                    switch (widget.label) {
                      case 'Email':
                        try {
                          currentUser?.verifyBeforeUpdateEmail(controller.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Check your Email to Verify')));
                          Navigator.pushNamed(context, '/login');
                        } on FirebaseAuthException {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Update Failed')));
                        }
                        break;
                      case 'Password':
                        try {
                          currentUser?.updatePassword(controller.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Password Updated')));
                          Navigator.pushNamed(context, '/login');
                        } on FirebaseAuthException {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Update Failed')));
                        }
                        break;
                      case 'Bio':
                        reference
                            .child('users/${currentUser?.uid}/bio')
                            .set(controller.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bio Updated')));
                        break;
                    }
                  },
                )),
          ),
        ),
      ),
    ]);
  }
}
