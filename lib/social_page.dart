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

void _openRequestDialog(BuildContext context, String name) async {
  bool budgetAccess = false;
  bool calendarAccess = false;
  DataSnapshot user = await reference.child('users/${currentUser?.uid}').get();
  if (user.hasChild('permissions') && user.child('permissions').hasChild(name)) {
    if (user.child('permissions').child(name).hasChild('budgets')) {
      budgetAccess = true;
    }
    if (user.child('permissions').child(name).hasChild('calendar')) {
      calendarAccess = true;
    }
  }
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Stack(children: <Widget>[
        Positioned(
          right: -40,
          top: -40,
          child: InkResponse(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.close),
            ),
          ),
        ),
        Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "View $name's financial information",
                  style: const TextStyle(fontSize: 20),
                )
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: Text(budgetAccess ? 'View Budgets' : 'Request Budgets'),
                  onPressed: () {
                    if (budgetAccess) {
                      _viewBudgets(context, name);
                    } else {
                      _sendBudgetRequest(context, name);
                    }
                  }
                )
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: Text(calendarAccess ? 'View Bill Calendar' : 'Request Bill Calendar'),
                  onPressed: () {
                    if (calendarAccess) {
                      _viewCalendar(context, name);
                    } else {
                      _sendCalendarRequest(context, name);
                    }
                  }
                )
              ),
            ]
          )
        ),
      ]),
    )
  );
}

void _sendBudgetRequest(BuildContext context, String name) async {
  try {
    String userName = currentUser?.displayName as String;
    String? friendUid = await getUidFromName(name);
    DatabaseReference notifRef = reference.child('users/$friendUid/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Budgets',
      'note': 'Your friend $userName would like to view your budgets.',
    });
    notifRef.child('state').set(1);
  } catch (error) {
    print(error);
  }
}

 DataRow _getDataRow(index, data) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(data['title'])),
        DataCell(Text(data['note'])),
        DataCell(Text(data['duedate'])),
      ],
    );
  }

void _viewBudgets(BuildContext context, String name) async {
  String? friendUid = await getUidFromName(name);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Stack(children: <Widget>[
        Positioned(
          right: -40,
          top: -40,
          child: InkResponse(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.close),
            ),
          ),
        ),
        Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "$name's Budgets",
                  style: const TextStyle(fontSize: 24),
                )
              ),
              FutureBuilder(
                future: reference.child(friendUid!).child('budgets').get(), 
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Map<String, dynamic> results = snapshot.data as Map<String, dynamic>;
                    if (results.length != 0) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.green,
                          ),
                          columnSpacing: 30,
                          columns: [
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Note')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(
                            results.length,
                            (index) => _getDataRow(
                              index,
                              results[index],
                            ),
                          ),
                          showBottomBorder: true,
                        ),
                      );
                    } else {
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('This user has no budgets'),
                          ),
                        ],
                      );
                    }
                  } else {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(),
                        ),
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No Data Found...'),
                        ),
                      ],
                    );
                  }
                }
              ),
            ]
          )
        ),
      ]),
    )
  );
}

void _sendCalendarRequest(BuildContext context, String name) async {
  try {
    String userName = currentUser?.displayName as String;
    DatabaseReference notifRef = reference.child('users/${currentUser?.uid}/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Calendar',
      'note': 'Your friend $userName would like to view your bill calendar.',
    });
    notifRef.child('state').set(1);
  } catch (error) {
    print(error);
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
                            Row(
                              children: [
                                ElevatedButton(
                                  child: const Text("View"),
                                  onPressed: () {
                                    if (friendStatus[userNames[index]] == true) {
                                      _openRequestDialog(context, userNames[index]);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You must be friends with this user to do this.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 5),
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
                              ]
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
