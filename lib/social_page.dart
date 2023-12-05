import 'dart:async';

import 'package:financefriend/ff_appbar.dart';
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

Future<String?> getUidFromName(String name) async {
  if (currentUser != null) {
    DatabaseEvent event = await reference.child('userIndex').once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<String, dynamic> userIndex = snapshot.value as Map<String, dynamic>;
      return userIndex[name];
    }
  }
  return null;
}

Future<bool> addUserAsFriend(String name) async {
  if (currentUser != null) {
    String? friendUid = await getUidFromName(name);
    DatabaseEvent preEvent2 = await reference.child('users/$friendUid').once();
    DataSnapshot preSnapshot2 = preEvent2.snapshot;

    if (preSnapshot2.value != null) {
      Map<String, dynamic> friendData =
          preSnapshot2.value as Map<String, dynamic>;
      // print("Friend Data:");
      // print(friendData);
      if (friendData.containsKey("friends")) {
        DatabaseEvent event2 =
            await reference.child('users/${friendUid}/friends').once();
        DataSnapshot snapshot2 = event2.snapshot;
        if (snapshot2.value != null) {
          String? userName = currentUser!.displayName;
          Map<String, dynamic> friendMap =
              snapshot2.value as Map<String, dynamic>;

          //Check if friend to add has blocked the current user
          if (friendMap[userName!] == 'blocked') return false;

          friendMap[userName] = userName;
          reference
              .child('users')
              .child(friendUid!)
              .child('friends')
              .set(friendMap);
        }
      } else {
        String? userName = currentUser!.displayName;
        Map<String, String> friendMap = {};
        friendMap[userName!] = userName;
        reference.child('users').child(friendUid!).child('friends').push();
        reference
            .child('users')
            .child(friendUid)
            .child('friends')
            .set(friendMap);
      }
    }

    String uid = currentUser!.uid;

    DatabaseEvent preEvent = await reference.child('users/$uid').once();
    DataSnapshot preSnapshot = preEvent.snapshot;
    if (preSnapshot.value != null) {
      Map<String, dynamic> userData = preSnapshot.value as Map<String, dynamic>;
      if (userData.containsKey("friends")) {
        DatabaseEvent event =
            await reference.child('users/$uid/friends').once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          Map<String, dynamic> friendMap =
              snapshot.value as Map<String, dynamic>;
          // print(friendMap);
          friendMap[name] = name;
          reference.child('users').child(uid).child('friends').set(friendMap);
        }
      } else {
        Map<String, String> friendMap = {};
        friendMap[name] = name;
        reference.child('users').child(uid).child('friends').push();
        reference.child('users').child(uid).child('friends').set(friendMap);
      }
      // print(userData);
    }
    return true;
  }
  return false;
}

Future<void> removeUserAsFriend(String name) async {
  if (currentUser != null) {
    String uid = currentUser!.uid;

    reference.child('users').child(uid).child('friends').child(name).remove();
    String? friendUid = await getUidFromName(name);

    String userName = currentUser?.displayName as String;

    reference
        .child('users')
        .child(friendUid!)
        .child('friends')
        .child(userName)
        .remove();
  }
}

Future<void> blockUser(String name) async {
  if (currentUser != null) {
    String uid = currentUser!.uid;

    reference
        .child('users')
        .child(uid)
        .child('friends')
        .child(name)
        .set('blocked');
    String? friendUid = await getUidFromName(name);

    String userName = currentUser?.displayName as String;

    reference
        .child('users')
        .child(friendUid!)
        .child('friends')
        .child(userName)
        .remove();
  }
}

Future<void> unblockUser(String name) async {
  if (currentUser != null) {
    String uid = currentUser!.uid;

    reference.child('users').child(uid).child('friends').child(name).set(name);
  }
}

Future<List<String>> getGoalsFromName(String name) async {
  if (currentUser != null) {
    DatabaseEvent userDataEvent =
        await reference.child('users/${await getUidFromName(name)}').once();
    DataSnapshot userData = userDataEvent.snapshot;

    Map<String, dynamic>? userDataMap = userData.value as Map<String, dynamic>?;

    if (userDataMap != null && userDataMap.containsKey('goals')) {
      List<dynamic> goalsDynamic = userDataMap['goals'] ?? [];

      // Convert each element in the dynamic list to String
      List<String> goals = goalsDynamic.map((goal) => goal.toString()).toList();

      return goals;
    } else {
      return ["$name does not currently have"];
    }
  }
  return [];
}

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

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadUserFriends();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const FFAppBar(),
        body: Column(
          children: [
            const SizedBox(
              height: 100,
            ),
            Row(
              children: [
                const SizedBox(width: 100),
                AddFriendsWidget(
                  userNames: userNames,
                  friendList: userFriends,
                  friendStatus: friendStatus,
                  onAddFriend: addUserAsFriend,
                  onRemoveFriend: removeUserAsFriend,
                  onBlock: blockUser,
                  onUnblock: unblockUser,
                ),
                const SizedBox(
                  width: 100,
                ),
                FriendGoalsWidget(
                  friends: userFriends,
                  friendGoalMap: friendGoalsMap,
                )
              ],
            ),
          ],
        ));
  }
}

class FriendTile extends StatelessWidget {
  final String name;
  final List<String> goals;

  const FriendTile({
    Key? key,
    required this.name,
    required this.goals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getProfilePictureUrl(),
      builder: (context, snapshot) {
        String profilePictureUrl =
            snapshot.data ?? ''; // Use an empty string as a fallback

        return ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(profilePictureUrl),
                    radius: 20,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    TextSpan(
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
        );
      },
    );
  }

  Future<String> getProfilePictureUrl() async {
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

class FriendGoalsWidget extends StatefulWidget {
  final List<String> friends;
  final Map<String, List<String>> friendGoalMap;

  const FriendGoalsWidget({
    Key? key,
    required this.friends,
    required this.friendGoalMap,
  }) : super(key: key);

  @override
  _FriendGoalsWidgetState createState() => _FriendGoalsWidgetState();
}

class _FriendGoalsWidgetState extends State<FriendGoalsWidget> {
  Future<void> loadFriendGoals(String friendName) async {
    List<String> goals = await getGoalsFromName(friendName);
    widget.friendGoalMap[friendName] = goals;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
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
                future: fetchFriendGoals(),
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

                        return FriendTile(
                          name: friendName,
                          goals: friendGoals,
                        );
                      },
                    );
                  }
                },
              ),
      ),
    );
  }

  Future<void> fetchFriendGoals() async {
    // Use Future.forEach to ensure asynchronous tasks complete sequentially
    await Future.forEach(widget.friends, (friendName) async {
      await loadFriendGoals(friendName);
    });
  }
}

class AddFriendsWidget extends StatefulWidget {
  final List<String> userNames;
  final List<String> friendList;
  final Map<String, int> friendStatus;
  final Function(String) onAddFriend;
  final Function(String) onRemoveFriend;
  final Function(String) onBlock;
  final Function(String) onUnblock;

  const AddFriendsWidget({
    Key? key,
    required this.userNames,
    required this.friendList,
    required this.friendStatus,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onBlock,
    required this.onUnblock,
  }) : super(key: key);

  @override
  _AddFriendsWidgetState createState() => _AddFriendsWidgetState();
}

class _AddFriendsWidgetState extends State<AddFriendsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: 400,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("Add Friends:", style: TextStyle(fontSize: 20)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.userNames.length,
                itemBuilder: (context, index) {
                  // print(widget.friendStatus.toString());
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.userNames[index]),
                        ElevatedButton(
                          child: Text(
                            widget.friendStatus[widget.userNames[index]] == 2
                                ? "Unblock"
                                : "Block",
                          ),
                          onPressed: () {
                            int status;
                            if (widget.friendStatus[widget.userNames[index]] ==
                                2) {
                              widget.onUnblock(widget.userNames[index]);
                              status = 0;
                            } else {
                              widget.onBlock(widget.userNames[index]);
                              widget.friendList.remove(widget.userNames[index]);
                              status = 2;
                            }
                            setState(() {
                              widget.friendStatus[widget.userNames[index]] =
                                  status;
                            });
                          },
                        ),
                        ElevatedButton(
                          child: Text(
                            widget.friendStatus[widget.userNames[index]] == 1
                                ? "Remove Friend"
                                : "Add Friend",
                          ),
                          onPressed: () async {
                            int? status =
                                widget.friendStatus[widget.userNames[index]];
                            if (widget.friendStatus[widget.userNames[index]] ==
                                1) {
                              widget.onRemoveFriend(widget.userNames[index]);
                              widget.friendList.remove(widget.userNames[index]);
                              status = 0;
                            } else {
                              if (await widget.onAddFriend(widget.userNames[index])) {
                                widget.friendList.add(widget.userNames[index]);
                                status = 1;
                              }
                            }
                            setState(() {
                              widget.friendStatus[widget.userNames[index]] =
                                  status!;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
