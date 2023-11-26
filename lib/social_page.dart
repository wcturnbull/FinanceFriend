import 'dart:async';

import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
  app: firebaseApp,
  databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/",
);
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
}

Future<void> addUserAsFriend(String name) async {
  if (currentUser != null) {
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
          print(friendMap);
          friendMap[name] = name;
          reference.child('users').child(uid).child('friends').set(friendMap);
        }
      } else {
        print("NO FRIENDS YET USER");

        Map<String, String> friendMap = {};
        friendMap[name] = name;
        reference.child('users').child(uid).child('friends').push();
        reference.child('users').child(uid).child('friends').set(friendMap);
      }
      print(userData);
    }
    String? friendUid = await getUidFromName(name);

    DatabaseEvent preEvent2 = await reference.child('users/$friendUid').once();
    DataSnapshot preSnapshot2 = preEvent2.snapshot;

    if (preSnapshot2.value != null) {
      Map<String, dynamic> friendData =
          preSnapshot2.value as Map<String, dynamic>;
      print("Friend Data:");
      print(friendData);
      if (friendData.containsKey("friends")) {
        DatabaseEvent event2 =
            await reference.child('users/${friendUid}/friends').once();
        DataSnapshot snapshot2 = event2.snapshot;
        if (snapshot2.value != null) {
          String? userName = currentUser!.displayName;
          Map<String, dynamic> friendMap =
              snapshot2.value as Map<String, dynamic>;
          friendMap[userName!] = userName;
          reference
              .child('users')
              .child(friendUid!)
              .child('friends')
              .set(friendMap);
        }
      } else {
        print("NO FRIENDS YET FRIEND");
        String? userName = currentUser!.displayName;
        Map<String, String> friendMap = {};
        friendMap[userName!] = userName;
        reference.child('users').child(friendUid!).child('friends').push();
        reference
            .child('users')
            .child(friendUid!)
            .child('friends')
            .set(friendMap);
      }
    }
  }
}

Future<void> removeUserAsFriend(String name) async {
  if (currentUser != null) {
    String uid = currentUser!.uid;

    reference.child('users').child(uid).child('friends').child(name).remove();
    String? friendUid = await getUidFromName(name);

    String userName = currentUser?.displayName as String;

    // List<String> otherFriendMap = [userName];

    reference
        .child('users')
        .child(friendUid!)
        .child('friends')
        .child(userName)
        .remove();
  }
}

class SocialPage extends StatefulWidget {
  const SocialPage({Key? key}) : super(key: key);

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  List<String> userNames = [];
  List<String> userFriends = [];
  Map<String, bool> friendStatus =
      {}; // Keep track of friend status for each user

  @override
  void initState() {
    super.initState();

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

    reference
        .child('users')
        .child(currentUser!.uid)
        .child('friends')
        .onValue
        .listen((event) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value is Map) {
        Map<String, dynamic> friendMap =
            Map<String, dynamic>.from(snapshot.value as Map<String, dynamic>);
        userFriends = friendMap.keys.toList();

        print("Current User Friends:");
        print(userFriends);

        // Update the UI
        setState(() {
          // Update friend status for each user
          friendStatus = {};
          for (var userName in userNames) {
            friendStatus[userName] = userFriends.contains(userName);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: Center(
        child: Container(
          height: 500,
          width: 400,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black, // You can set the border color
              width: 2.0, // You can set the border width
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Column(
              children: [
                Text("Other Users:", style: TextStyle(fontSize: 20)),
                // Use a ListView.builder to display the user names
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: userNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(userNames[index]),
                            ElevatedButton(
                              child: Text(friendStatus[userNames[index]] == true
                                  ? "Remove Friend"
                                  : "Add Friend"),
                              onPressed: () {
                                // Handle the button click here
                                // You can add the logic to do something when the button is clicked
                                if (friendStatus[userNames[index]] == true) {
                                  // User is already a friend, so remove
                                  removeUserAsFriend(userNames[index]);
                                } else {
                                  // User is not a friend, so add
                                  addUserAsFriend(userNames[index]);
                                }
                                setState(() {
                                  // Update the friend status for the clicked user
                                  friendStatus[userNames[index]] =
                                      !friendStatus[userNames[index]]!;
                                });
                              },
                            ),
                          ],
                        ),
                        // You can customize the ListTile as needed
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
