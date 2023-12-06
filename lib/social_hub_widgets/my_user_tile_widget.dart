import 'dart:async';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class MyUserTile extends StatelessWidget {
  final String name;
  final List<String> goals;

  const MyUserTile({
    Key? key,
    required this.name,
    required this.goals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getProfilePictureUrl(name),
      builder: (context, snapshot) {
        String profilePictureUrl =
            snapshot.data ?? ''; // Use an empty string as a fallback

        return ListTile(
          title: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profilePictureUrl),
                      radius: 20,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text("$name (you)",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Goals: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: goals.join(', '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> getProfilePictureUrl(String name) async {
    String userUID = await getUidFromName(name) ?? '';
    DatabaseEvent event =
        await reference.child('users/$userUID/profilePic').once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      return snapshot.value.toString();
    } else {
      return ''; // Return an empty string if the profile picture URL is not found
    }
  }
}