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
          friendMap[userName!] = userName;
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

    reference
        .child('users')
        .child(friendUid!)
        .child('friends')
        .child(userName)
        .remove();
  }
}

void _openRequestDialog(BuildContext context, String friendName) async {
  //Opens popup window allowing user to request or view a friend's financials
  bool budgetAccess = false;
  bool calendarAccess = false;
  String userName = currentUser?.displayName as String;
  String? friendUid = await getUidFromName(friendName);
  DataSnapshot user = await reference.child('users/$friendUid').get();
  if (user.hasChild('settings') && user.child('settings').hasChild('permissions')) {
    DataSnapshot perms = await reference.child('users/$friendUid/settings/permissions/$userName').get();
    Map<String, dynamic> permsMap = perms.value as Map<String, dynamic>;
    permsMap.forEach((key, value) {
      if (key == 'budgets') budgetAccess = value;
      if (key == 'calendar') calendarAccess = value;
    });
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
                  "View $friendName's financial information",
                  style: const TextStyle(fontSize: 20),
                )
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: Text(budgetAccess ? 'View Budgets' : 'Request Budgets'),
                  onPressed: () {
                    if (budgetAccess) {
                      _viewBudgets(context, friendName);
                    } else {
                      _sendBudgetRequest(context, friendName);
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
                      _viewCalendar(context, friendName);
                    } else {
                      _sendCalendarRequest(context, friendName);
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

void _sendBudgetRequest(BuildContext context, String friendName) async {
  //Sends a request via notification to view a friend's budgets
  try {
    String userName = currentUser?.displayName as String;
    String? friendUid = await getUidFromName(friendName);
    DatabaseReference notifRef = reference.child('users/$friendUid/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Budgets',
      'note': 'Your friend $userName would like to view your budgets.',
    });
    notifRef.child('state').set(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Budget request sent successfully!',
        ),
      ),
    );
  } catch (error) {
    print(error);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Budget request failed to send due to an error.',
        ),
      ),
    );
  }
}

void _sendCalendarRequest(BuildContext context, String friendName) async {
  //Sends a request via notification to view a friend's bill tracking calendar
  try {
    String userName = currentUser?.displayName as String;
    String? friendUid = await getUidFromName(friendName);
    DatabaseReference notifRef = reference.child('users/$friendUid/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Calendar',
      'note': 'Your friend $userName would like to view your bill calendar.',
    });
    notifRef.child('state').set(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calendar request sent successfully!',
        ),
      ),
    );
  } catch (error) {
    print(error);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calendar request failed to send due to an error.',
        ),
      ),
    );
  }
}

void _viewBudgets(BuildContext context, String friendName) async {
  //Opens a popup window containing a friend's budgets
  String? friendUid = await getUidFromName(friendName);
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
                  "$friendName's Budgets",
                  style: const TextStyle(fontSize: 24),
                )
              ),
              FutureBuilder(
                future: reference.child('users/$friendUid/budgets').get(), 
                builder: (context, snapshot) {
                  if (snapshot.data != null && snapshot.data?.value != null) {
                    Map<String, dynamic> results = snapshot.data?.value as Map<String, dynamic>;
                    List<Map<String, dynamic>> budgets = [];
                    results.forEach((key, value) {
                      budgets.add({
                        'budgetName': value['budgetName'].toString(),
                        'budgetMap': value['budgetMap'],
                      });
                    });
                    if (budgets.length != 0) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.green,
                          ),
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Items')),
                          ],
                          rows: List.generate(
                            budgets.length,
                            (index) => _getBudgetRow(
                              index,
                              budgets[index],
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
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('This user has no budgets'),
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

DataRow _getBudgetRow(index, data) {
  //Used to display budgets in a table format
  String budgetMap = '';
  data['budgetMap'].forEach((key, value) {
    budgetMap += '$key: \$$value, ';
  });
  budgetMap = budgetMap.substring(0, budgetMap.lastIndexOf(', '));
  return DataRow(
    cells: <DataCell>[
      DataCell(Text(data['budgetName'])),
      DataCell(Text(budgetMap)),
    ],
  );
}

void _viewCalendar(context, friendName) async {
  //Opens a popup window containing a friend's budgets
  String? friendUid = await getUidFromName(friendName);
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
                  "$friendName's Bill Calendar",
                  style: const TextStyle(fontSize: 24),
                )
              ),
              FutureBuilder(
                future: reference.child('users/$friendUid/bills').get(), 
                builder: (context, snapshot) {
                  if (snapshot.data != null && snapshot.data?.value != null) {
                    Map<String, dynamic> results = snapshot.data?.value as Map<String, dynamic>;
                    List<Map<String, String>> bills = [];
                    results.forEach((key, value) {
                      bills.add({
                        'title': value['title'].toString(),
                        'amount': value['amount'].toString(),
                        'duedate': value['duedate'].toString(),
                      });
                    });
                    if (bills.length != 0) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.green,
                          ),
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Due Date')),
                          ],
                          rows: List.generate(
                            bills.length,
                            (index) => _getBillRow(
                              index,
                              bills[index],
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
                            child: Text('This user has no bills'),
                          ),
                        ],
                      );
                    }
                  } else {
                    return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('This user has no bills'),
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

DataRow _getBillRow(index, data) {
  //Used to display bills in a table format
  return DataRow(
    cells: <DataCell>[
      DataCell(Text(data['title'])),
      DataCell(Text(data['amount'])),
      DataCell(Text(data['duedate'])),
    ],
  );
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
  Map<String, bool> friendStatus = {};
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
          friendStatus[userName] = userFriends.contains(userName);
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
        appBar: FFAppBar(),
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
                ),
                const SizedBox(
                  width: 100,
                ),
                FriendGoalsWidget(
                  friends: userFriends,
                  friendGoalMap: friendGoalsMap,
                ),
                // Add the ChallengesBox here
                const SizedBox(width: 100),
                ChallengesBox(),
              ],
            ),
          ],
        ));
  }
}

class ChallengesBox extends StatefulWidget {
  @override
  _ChallengesBoxState createState() => _ChallengesBoxState();
}

class _ChallengesBoxState extends State<ChallengesBox> {
  String customChallengeMessage = "";
  bool isJoined = false;
  List<Map<String, dynamic>> challenges = [];

  @override
  void initState() {
    super.initState();
    // Fetch challenges when the widget is first created
    fetchChallenges();
  }

  Future<void> fetchChallenges() async {
    if (currentUser != null) {
      String uid = currentUser!.uid;

      // Retrieve the list of challenges from the Firebase database
      DatabaseEvent challengesEvent =
          await reference.child('users/$uid/challenges').once();
      DataSnapshot challengesSnapshot = challengesEvent.snapshot;

      if (challengesSnapshot.value == null) {
        // If the challenges section is null, create an initial challenge
        String initialMessage = "Default Challenge Message";
        String initialStatus = "not joined";

        await reference.child('users/$uid/challenges').push().set({
          'message': initialMessage,
          'status': initialStatus,
        });

        // Fetch the challenges again after adding the initial challenge
        await fetchChallenges();
      } else {
        // The challenges section exists, fetch and display challenges
        Map<String, dynamic> challengesData =
            challengesSnapshot.value as Map<String, dynamic>;

        challenges = challengesData.entries
            .map((entry) => {
                  'key': entry.key,
                  'message': entry.value['message'],
                  'status': entry.value['status'],
                })
            .toList();

        // Update the UI to display challenges
        setState(() {});
      }
    }
  }

  Future<void> getOverBudgetCategory() async {
    if (currentUser != null) {
      String uid = currentUser!.uid;

      // Retrieve the user's budget information from Firebase
      DatabaseEvent budgetsEvent =
          await reference.child('users/$uid/budgets').once();
      DataSnapshot budgetsSnapshot = budgetsEvent.snapshot;

      if (budgetsSnapshot.value != null) {
        Map<String, dynamic> budgetsData =
            budgetsSnapshot.value as Map<String, dynamic>;

        // Find the budget with the highest expense
        String overBudgetCategory = "";
        double maxExpensePrice = 0.0;

        budgetsData.forEach((budgetName, budgetData) {
          if (budgetData.containsKey('expenses')) {
            dynamic expensesData = budgetData['expenses'];

            if (expensesData is List) {
              for (var expenseData in expensesData) {
                double price = expenseData['price'] ?? 0.0;

                if (price > maxExpensePrice) {
                  maxExpensePrice = price;
                  overBudgetCategory = expenseData['category'] ?? "";
                }
              }
            }
          }
        });

        // Save the custom challenge message to the Firebase database
        String challengeMessage =
            "Try to spend less in the \"$overBudgetCategory\" category!";
        await reference.child('users/$uid/challenges').push().set({
          'message': challengeMessage,
          'status': "not joined",
        });

        // Display the over-budget category in the custom challenge message
        setState(() {
          customChallengeMessage = challengeMessage;
          isJoined = false; // Reset the join status
        });
      }
    }
  }

  Future<void> joinChallenge(String challengeKey) async {
    if (currentUser != null) {
      String uid = currentUser!.uid;

      // Set the status of the challenge to "joined" in the database
      await reference
          .child('users/$uid/challenges/$challengeKey')
          .update({'status': 'joined'});

      // Update the UI to show the "Leave" button
      setState(() {
        isJoined = true;
      });
      fetchChallenges();
    }
  }

  Future<void> leaveChallenge(String challengeKey) async {
    if (currentUser != null) {
      String uid = currentUser!.uid;

      // Set the status of the challenge to "not joined" in the database
      await reference
          .child('users/$uid/challenges/$challengeKey')
          .update({'status': 'not joined'});

      // Update the UI to show the "Join" button
      setState(() {
        isJoined = false;
      });
      fetchChallenges();
    }
  }

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
            const Text("Challenges:", style: TextStyle(fontSize: 20)),
            const Divider(),
            ElevatedButton(
              child: Text("Custom Challenge"),
              onPressed: () {
                // Display the custom challenge message
                getOverBudgetCategory();
                fetchChallenges();
              },
            ),
            const SizedBox(height: 10),
            if (challenges.isNotEmpty)
              ...challenges.map((challenge) {
                return Column(
                  children: [
                    Text(
                      challenge['message'],
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    if (challenge['status'] == 'not joined') ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        child: Text("Join"),
                        onPressed: () {
                          // Update the UI to show the "Leave" button
                          joinChallenge(challenge['key']);
                          setState(() {
                            isJoined = true;
                          });
                        },
                      ),
                    ],
                    if (challenge['status'] == 'joined') ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        child: Text("Leave"),
                        onPressed: () {
                          leaveChallenge(challenge['key']);
                          // Update the UI to show the "Join" button
                          setState(() {
                            isJoined = false;
                          });
                        },
                      ),
                    ],
                  ],
                );
              }),
            // Add other challenge-related content here if needed
          ],
        ),
      ),
    );
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
  final Map<String, bool> friendStatus;
  final Function(String) onAddFriend;
  final Function(String) onRemoveFriend;

  const AddFriendsWidget({
    Key? key,
    required this.userNames,
    required this.friendList,
    required this.friendStatus,
    required this.onAddFriend,
    required this.onRemoveFriend,
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
                        Row(
                          children: [
                            ElevatedButton(
                              child: const Text("View"),
                              onPressed: () {
                                if (widget.friendStatus[widget.userNames[index]] == true) {
                                  _openRequestDialog(context, widget.userNames[index]);
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
                              child: Text(
                                widget.friendStatus[widget.userNames[index]] == true
                                    ? "Remove Friend"
                                    : "Add Friend",
                              ),
                              onPressed: () {
                                if (widget.friendStatus[widget.userNames[index]] ==
                                    true) {
                                  widget.onRemoveFriend(widget.userNames[index]);
                                  widget.friendList.remove(widget.userNames[index]);
                                } else {
                                  widget.onAddFriend(widget.userNames[index]);
                                  widget.friendList.add(widget.userNames[index]);
                                }
                                setState(() {
                                  widget.friendStatus[widget.userNames[index]] =
                                      !widget
                                          .friendStatus[widget.userNames[index]]!;
                                });
                              },
                            ),
                          ]
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
