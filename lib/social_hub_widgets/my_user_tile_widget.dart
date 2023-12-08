import 'dart:async';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/social_hub_widgets/friend_helpers.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class MyUserTile extends StatefulWidget {
  final String name;
  final List<String> goals;
  final Map<String, List<String>> challengeMap;

  MyUserTile({
    Key? key,
    required this.challengeMap,
    required this.name,
    required this.goals,
  }) : super(key: key);

  @override
  _MyUserTileState createState() => _MyUserTileState();
}

class _MyUserTileState extends State<MyUserTile> {
  late String profilePictureUrl;
  late List<String> userChallenges;

  Future<String> fetchChallengesAndProfilePic() async {
    userChallenges =
        await getChallengesFromName(currentUser?.displayName ?? "");
    profilePictureUrl = await getProfilePictureUrl(currentUser?.photoURL ?? '');

    return profilePictureUrl; // Return the profile picture URL
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // Specify the type parameter for FutureBuilder
      future: fetchChallengesAndProfilePic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String profilePictureUrl = snapshot.data as String? ?? '';
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
                      Text(
                        "${widget.name} (you)",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                          text: widget.goals.join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Challenges Joined: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: userChallenges.join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
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
