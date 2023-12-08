import 'dart:async';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
import 'package:financefriend/social_hub_widgets/create_post_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;
final userCommentsReference =
    reference.child('users/${currentUser?.uid}/goalsComments');
Map<String, dynamic> comments = {};

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
    userChallenges = await getChallengesFromName(widget.name);
    profilePictureUrl = await getProfilePictureUrl(widget.name);

    return profilePictureUrl; // Return the profile picture URL
  }

  @override
  void initState() {
    super.initState();
    initializeComments();
    userCommentsReference.onValue.listen((event) {
      setState(() {
        initializeComments();
      });
    });
  }

  void initializeComments() async {
    final DataSnapshot commentsSnapshot = await userCommentsReference.get();

    if (commentsSnapshot.exists) {
      Map<String, dynamic>? commentList =
          commentsSnapshot.value as Map<String, dynamic>?;
      setState(() {
        comments = commentList!;
      });
    }
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CreatePost();
                              });
                        },
                        child: const Text("Create Post"),
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
                        const TextSpan(
                          text: '\n',
                        ),
                        ...comments.entries.map(
                            (e) => TextSpan(text: '${e.key}: ${e.value}\n')),
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
