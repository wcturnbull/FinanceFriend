import 'dart:async';

import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
import 'package:financefriend/social_hub_widgets/request_helpers.dart';
import 'package:financefriend/social_hub_widgets/direct_messages.dart';
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
        // String initialMessage = "Default Challenge Message";
        // String initialStatus = "not joined";

        // await reference.child('users/$uid/challenges').push().set({
        //   'message': initialMessage,
        //   'status': initialStatus,
        // });

        // // Fetch the challenges again after adding the initial challenge
        // await fetchChallenges();
        challenges = [];
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

  Future<void> deleteChallenge(String challengeKey) async {
    if (currentUser != null) {
      String uid = currentUser!.uid;

      await reference.child('users/$uid/challenges/$challengeKey').remove();
      setState(() {});

      //print(challenges[challengeKey]);

      fetchChallenges();
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

        String challengeMessage = "";

        if (overBudgetCategory == "") {
          challengeMessage = "Add some expenses to your budgets!";
        } else {
          // Save the custom challenge message to the Firebase database
          challengeMessage =
              "Try to spend less in the \"$overBudgetCategory\" category!";
        }
        await reference.child('users/$uid/challenges').push().set({
          'message': challengeMessage,
          'status': "not joined",
        });

        // Display the over-budget category in the custom challenge message
        setState(() {
          customChallengeMessage = challengeMessage;
          isJoined = false; // Reset the join status
        });

        fetchChallenges();
      } else {
        await reference.child('users/$uid/challenges').push().set({
          'message': "Create a budget and add Expenses!",
          'status': "not joined",
        });
        setState(() {
          customChallengeMessage = "Create a budget and add Expenses!";
          isJoined = false;
        });
        fetchChallenges();
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

  Future<void> _createChallenge(BuildContext context) async {
    TextEditingController customChallengeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _createCustomBudgetChallenge();
                },
                child: Text("Custom Challenge"),
              ),
              // Add other challenge options here...

              SizedBox(height: 16),
              TextField(
                controller: customChallengeController,
                decoration: InputDecoration(
                  labelText: "Type Your Own Challenge",
                ),
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  String customChallenge = customChallengeController.text;
                  if (customChallenge.isNotEmpty) {
                    // Process the custom challenge, e.g., save it or use it
                    // You can replace the next line with your custom logic
                    _createCustomChallenge(customChallenge);
                    // print("Custom Challenge: $customChallenge");
                  }
                },
                child: Text("Add Challenge"),
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createCustomChallenge(String challengeMessage) async {
    String? uid = currentUser?.uid;
    await reference.child('users/$uid/challenges').push().set({
      'message': challengeMessage,
      'status': "not joined",
    });

    // Display the over-budget category in the custom challenge message
    setState(() {
      customChallengeMessage = challengeMessage;
      isJoined = false; // Reset the join status
    });

    fetchChallenges();
  }

  Future<void> _createCustomBudgetChallenge() async {
    // Display the custom challenge message
    await getOverBudgetCategory();
    fetchChallenges();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        "Challenges:",
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      Container(
        height: 500,
        width: 440,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                ElevatedButton(
                  child: Text("Create New Challenge"),
                  onPressed: () {
                    _createChallenge(context);
                  },
                ),
                const SizedBox(height: 10),
                if (challenges.isNotEmpty)
                  ...challenges.map((challenge) {
                    return Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              challenge['message'],
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      child: Text(
                                          challenge['status'] == 'not joined'
                                              ? "Join"
                                              : "Leave"),
                                      onPressed: () {
                                        if (challenge['status'] ==
                                            'not joined') {
                                          joinChallenge(challenge['key']);
                                          setState(() {
                                            isJoined = true;
                                          });
                                        } else {
                                          leaveChallenge(challenge['key']);
                                          setState(() {
                                            isJoined = false;
                                          });
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        deleteChallenge(challenge['key']);
                                        setState(() {});
                                      },
                                      child: Text("Delete"),
                                    ),
                                  ]),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ));
                  })
                else
                  Container(
                    alignment: Alignment.center,
                    child: Text("Click above to add a Challenge!"),
                  ),

                // Add other challenge-related content here if needed
              ],
            ),
          ),
        ),
      )
    ]);
  }
}
