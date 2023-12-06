import 'dart:async';

import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
import 'package:financefriend/social_hub_widgets/request_helpers.dart';
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
