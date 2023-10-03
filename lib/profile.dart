import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'profile_picture_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
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
                  Text(
                    '${currentUser!.displayName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      color: Colors.white
                    )
                  )
                ],
              ),
              const SizedBox(height: 16.0),

            ],
          ),
        ),
      ],
    )));
  }
}

class EditableTextWidget extends StatefulWidget {
  final String initialText;
  final Function(String) onSave;

  EditableTextWidget({required this.initialText, required this.onSave});

  @override
  _EditableTextWidgetState createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.initialText);
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
          decoration: InputDecoration(
            labelText: widget.initialText,
          ),
        ),
        SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () {
            final editedText = _textEditingController.text;
            widget.onSave(editedText);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
