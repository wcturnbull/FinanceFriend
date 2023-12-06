import 'dart:async';

import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
import 'package:financefriend/social_hub_widgets/request_helpers.dart';
import 'package:financefriend/social_hub_widgets/challenges_box_widget.dart';
import 'package:financefriend/social_hub_widgets/friend_tile_widget.dart';
import 'package:financefriend/social_hub_widgets/my_user_tile_widget.dart';
import 'package:financefriend/social_hub_widgets/friend_goals_widget.dart';
import 'package:financefriend/social_hub_widgets/add_friend_widget.dart';
import 'package:financefriend/direct_messages.dart';
import 'package:financefriend/ff_appbar.dart';
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

class SocialPage extends StatefulWidget {
  const SocialPage({Key? key}) : super(key: key);

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  List<String> userNames = [];
  List<String> userFriends = [];
  Map<String, int> friendStatus = {};
  //0: not friends  1: friends  2: blocked
  Map<String, List<String>> friendGoalsMap = {};
  Map<String, String> friendBioMap = {};
  String? name = "";
  List<String> userGoals = [];
  Map<String, String> profilePicUrls = {};

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadUserFriends();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    DatabaseEvent userDataEvent =
        await reference.child('users/${currentUser?.uid}').once();
    DataSnapshot userData = userDataEvent.snapshot;

    Map<String, dynamic>? userDataMap = userData.value as Map<String, dynamic>?;

    if (userDataMap != null && userDataMap.containsKey('goals')) {
      List<dynamic> goalsDynamic = userDataMap['goals'] ?? [];

      // Convert each element in the dynamic list to String
      List<String> goals = goalsDynamic.map((goal) => goal.toString()).toList();

      userGoals = goals;
      name = currentUser?.displayName;
    } else {
      userGoals = [
        "${currentUser?.displayName} does not currently have goals set."
      ];
    }
  }

  Future<void> loadUserFriends() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    // Use await to wait for the completion of the asynchronous operation
    DatabaseEvent event = await reference
        .child('users')
        .child(currentUser!.uid)
        .child('friends')
        .once();

    // Now you can work with the 'event'
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value is Map) {
      Map<String, dynamic> friendMap =
          Map<String, dynamic>.from(snapshot.value as Map<String, dynamic>);
      userFriends = friendMap.keys.toList();

      // Initialize friendStatus based on existing friends
      List<Future<void>> futures = [];
      for (var userName in userNames) {
        futures.add(loadFriendGoals(userName));
      }
      await Future.wait(futures);

      for (var userName in userNames) {
        profilePicUrls[userName] = await getProfilePictureUrl(userName);
      }

      profilePicUrls[currentUser.displayName ?? ""] =
          currentUser.photoURL ?? "";

      setState(() {
        for (var userName in userNames) {
          if (userFriends.contains(userName)) {
            friendStatus[userName] = 1;
          } else if (userFriends.contains('blocked')) {
            friendStatus[userName] = 2;
          } else {
            friendStatus[userName] = 0;
          }
        }
      });
    }
  }

  Future<void> loadUsers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    reference.child('users').onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value is Map) {
        userNames.clear();

        (snapshot.value as Map).forEach((key, value) {
          if (value is Map &&
              value.containsKey('name') &&
              value.containsKey('bio')) {
            String name = value['name'];
            if (name != currentUser?.displayName) {
              userNames.add(name);
            }
            reference.child('userIndex').child(value['name']).set(key);
          }
        });

        // Update the UI
        setState(() {});
      }
    });
  }

  Future<void> loadFriendGoals(String friendName) async {
    List<String> goals = await getGoalsFromName(friendName);
    friendGoalsMap[friendName] = goals;
  }

  Future<void> loadFriendBios(String friendName) async {
    String bio = await getBioFromName(friendName);
    friendBioMap[friendName] = bio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        "FinanceFriend Users:",
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                      AddFriendsWidget(
                        userNames: userNames,
                        bios: friendBioMap,
                        profilePicUrls: profilePicUrls,
                        friendList: userFriends,
                        friendStatus: friendStatus,
                        onAddFriend: addUserAsFriend,
                        onRemoveFriend: removeUserAsFriend,
                        onBlock: blockUser,
                        onUnblock: unblockUser,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Friends:",
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        height: 110,
                        width: 400,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              MyUserTile(
                                name: ("$name") ?? '',
                                goals: userGoals,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      FriendGoalsWidget(
                        users: userNames,
                        friends: userFriends,
                        friendGoalMap: friendGoalsMap,
                        friendBioMap: friendBioMap,
                      ),
                    ],
                  ),
                  ChallengesBox(),
                ],
              ),
            ),
            SizedBox(height: 50),
            DirectMessages(
              userName: currentUser?.displayName ?? "",
              friendsList: userFriends,
              friendsProfilePics: profilePicUrls,
            ),
          ],
        ),
      ),
    );
  }
}
