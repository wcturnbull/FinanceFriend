import 'package:financefriend/ff_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: EditableTextWidget(),
              ),
            ],
          ),
        ),
      ],
    )));
  }
}

class EditableTextWidget extends StatefulWidget {
  EditableTextWidget({super.key});

  @override
  _EditableTextWidgetState createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _textEditingController;
  String currentText = '';

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();

    reference
        .child('users/${currentUser?.uid}/bio')
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          currentText = data.toString();
          _textEditingController.text = currentText;
        });
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _textEditingController,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () {
            final editedText = _textEditingController.text;

            // Update the text in the database
            reference.child('users/${currentUser?.uid}/bio').set(editedText);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
