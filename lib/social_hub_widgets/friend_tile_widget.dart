import 'dart:async';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/social_hub_widgets/request_helpers.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class FriendTile extends StatefulWidget {
  final String name;
  final List<String> goals;
  final List<String> challenges;
  final String bio;

  const FriendTile({
    Key? key,
    required this.name,
    required this.goals,
    required this.challenges,
    required this.bio,
  }) : super(key: key);

  @override
  _FriendTileState createState() => _FriendTileState();
}

class _FriendTileState extends State<FriendTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getProfilePictureUrl(widget.name),
      builder: (context, snapshot) {
        String profilePictureUrl = snapshot.data ?? '';

        return GestureDetector(
          onTap: () {
            _showUserProfileDialog(context, widget.name, profilePictureUrl,
                widget.goals, widget.challenges, widget.bio);
          },
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                isHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                isHovered = false;
              });
            },
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(profilePictureUrl),
                        radius: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHovered ? Colors.blue : Colors.black,
                          decoration: isHovered
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 30),
                      ElevatedButton(
                        child: const Text("View"),
                        onPressed: () {
                          openRequestDialog(context, widget.name);
                        },
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
                ],
              ),
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
      return '';
    }
  }

  void _showUserProfileDialog(
      BuildContext context,
      String name,
      String imageUrl,
      List<String> goals,
      List<String> challenges,
      String bio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name),
          content: Container(
            height: 400, // Set your desired height here
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                    radius: 60,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: RichText(
                    text: const TextSpan(children: <TextSpan>[
                      TextSpan(
                        text: "Friend Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "Friend")
                    ]),
                  ),
                ),
                const SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Bio: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: bio,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Goals:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: (goals.length > 1)
                            ? goals.join(',\n')
                            : goals.join('\n'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Challenges:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: challenges.join('\n'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
