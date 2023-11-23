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

void addUserAsFriend(String name) {
  if (currentUser != null) {
    String uid = currentUser!.uid;

    // Check if the user's friends list is initialized
    reference
        .child('users')
        .child(uid)
        .child('friends')
        .once()
        .then((DataSnapshot snapshot) {
          Map<dynamic, dynamic>? friendsMap =
              snapshot.value as Map<dynamic, dynamic>?;

          if (friendsMap == null) {
            // If the friends list is not initialized, initialize it with the new friend
            friendsMap = {name: true};
          } else {
            // Check if the user is not already a friend
            if (!friendsMap.containsKey(name)) {
              // If the user is not a friend, add them
              friendsMap[name] = true;
            } else {
              // If the user is already a friend, you can implement the logic to remove them
              // For now, let's just print a message
              print("User $name is already a friend.");
            }
          }

          // Update the user's friends list in the database
          reference.child('users').child(uid).child('friends').set(friendsMap);
        } as FutureOr Function(DatabaseEvent value))
        .catchError((error) {
      print("Error: $error");
    });
  }
}

class SocialPage extends StatefulWidget {
  const SocialPage({Key? key}) : super(key: key);

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  List<String> userNames = [];

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
                              child: Text("Add Friend"),
                              onPressed: () {
                                // Handle the button click here
                                // You can add the logic to do something when the button is clicked
                                addUserAsFriend(userNames[index]);
                                print(
                                    "Add button clicked for ${userNames[index]}");
                                // Optionally, you can update the UI to reflect the change
                                setState(() {
                                  // Update the button label to "Remove Friend" (not functional yet)
                                  // You may need to modify this logic based on whether the user is already a friend
                                  // For simplicity, this example assumes the user is not already a friend
                                  // If the user is already a friend, you can set the button label accordingly
                                  // For example, you could maintain a list of friends and check if the user is in that list
                                  // and set the button label accordingly.
                                  userNames[index] = "Remove Friend";
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
