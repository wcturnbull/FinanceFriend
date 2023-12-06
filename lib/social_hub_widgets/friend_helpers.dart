import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:financefriend/home.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

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
      return ["$name does not currently have goals set."];
    }
  }
  return [];
}

Future<String> getBioFromName(String name) async {
  if (currentUser != null) {
    DatabaseEvent userDataEvent =
        await reference.child('users/${await getUidFromName(name)}').once();
    DataSnapshot userData = userDataEvent.snapshot;

    Map<String, dynamic>? userDataMap = userData.value as Map<String, dynamic>?;

    if (userDataMap != null && userDataMap.containsKey('bio')) {
      String bio = userDataMap['bio'] ?? "$name does not have a bio";
      return bio;
    } else {
      return "$name does not have a bio";
    }
  }
  return "$name does not have a bio";
}

Future<List<String>> getChallengesFromName(String name) async {
  if (currentUser != null) {
    DatabaseEvent userDataEvent =
        await reference.child('users/${await getUidFromName(name)}').once();
    DataSnapshot userData = userDataEvent.snapshot;

    Map<String, dynamic>? userDataMap = userData.value as Map<String, dynamic>?;

    if (userDataMap != null && userDataMap.containsKey('challenges')) {
      Map<String, dynamic> challengesDynamic = userDataMap['challenges'] ?? [];
      List<String> challenges = [];
      challengesDynamic.forEach((key, value) {
        // print('Key: $key, Value: $value');
        // print("message: ${value['message']}");
        // print("status: ${value['status']}");
        if (value['status'] == "joined") {
          challenges.add(value['message']);
        }
      });
      // Convert each element in the dynamic list to String
      if (challenges.isEmpty) {
        challenges.add("$name has not currently joined any challenges.");
      }

      // print("user: $name\n challenges: $challenges");

      return challenges;
    } else {
      return ["$name has not currently joined any challenges."];
    }
  }
  return [];
}

Future<bool> addUserAsFriend(String name) async {
  if (currentUser != null) {
    String? friendUid = await getUidFromName(name);
    DatabaseEvent preEvent2 = await reference.child('users/$friendUid').once();
    DataSnapshot preSnapshot2 = preEvent2.snapshot;

    if (preSnapshot2.value != null) {
      Map<String, dynamic> friendData =
          preSnapshot2.value as Map<String, dynamic>;
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
