import 'dart:async';

import 'package:financefriend/social_hub_widgets/friend_tile_widget.dart';
import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
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

class FriendGoalsWidget extends StatefulWidget {
  final List<String> friends;
  final List<String> users;
  final Map<String, List<String>> friendGoalMap;
  final Map<String, List<String>> friendChallengesMap;
  final Map<String, String> friendBioMap;

  const FriendGoalsWidget({
    Key? key,
    required this.friends,
    required this.users,
    required this.friendGoalMap,
    required this.friendChallengesMap,
    required this.friendBioMap,
  }) : super(key: key);

  @override
  _FriendGoalsWidgetState createState() => _FriendGoalsWidgetState();
}

class _FriendGoalsWidgetState extends State<FriendGoalsWidget> {
  Future<void> loadFriendGoals(String friendName) async {
    List<String> goals = await getGoalsFromName(friendName);
    widget.friendGoalMap[friendName] = goals;
  }

  Future<void> loadFriendBios(String friendName) async {
    String bio = await getBioFromName(friendName);
    widget.friendBioMap[friendName] = bio;
  }

  Future<void> loadFriendChallenges(String friendName) async {
    List<String> challenges = await getChallengesFromName(friendName);
    widget.friendChallengesMap[friendName] = challenges;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 341,
      width: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2.0),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: widget.friends.isEmpty
            ? const Text("No Friends Yet")
            : FutureBuilder(
                // Use FutureBuilder to wait for all asynchronous tasks
                future: fetchFriendGoalsBio(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else {
                    return ListView.builder(
                      itemCount: widget.friends.length,
                      itemBuilder: (context, index) {
                        String friendName = widget.friends[index];
                        String profilePictureUrl =
                            currentUser!.photoURL as String;
                        List<String> friendGoals =
                            widget.friendGoalMap[friendName] ?? [];

                        String friendBio =
                            widget.friendBioMap[friendName] ?? "";

                        List<String> friendChallenges =
                            widget.friendChallengesMap[friendName] ?? [];

                        return FriendTile(
                          name: friendName,
                          challenges: friendChallenges,
                          goals: friendGoals,
                          bio: friendBio,
                        );
                      },
                    );
                  }
                },
              ),
      ),
    );
  }

  Future<void> fetchFriendGoalsBio() async {
    // Use Future.forEach to ensure asynchronous tasks complete sequentially
    await Future.forEach(widget.friends, (friendName) async {
      await loadFriendGoals(friendName);
    });

    await Future.forEach(widget.users, (friendName) async {
      await loadFriendBios(friendName);
    });

    await Future.forEach(widget.friends, (friendName) async {
      await loadFriendChallenges(friendName);
    });
  }
}
