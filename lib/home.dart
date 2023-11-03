import 'package:financefriend/budget_tracking_widgets/budget_colors.dart';
import 'package:financefriend/ff_appbar.dart';
import 'package:financefriend/profile_picture_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:financefriend/budget_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';
import 'dart:js' as js;

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _getInvestmentsPreview() {
    return 'Your investments can be found here!';
  }

  Future<String> _getBudgetsPreview() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    if (!user.hasChild('budgetMap')) {
      return 'Add some budgets to your budgeting page!';
    }

    DataSnapshot budgets = await userRef.child('budgetMap').get();
    Map<String, dynamic> budgetsMap = budgets.value as Map<String, dynamic>;
    String name = '', amount = '';
    budgetsMap.forEach((key, value) {
      name = key.toString();
      amount = value.toString();
    });

    return '\$' + amount + ' is allocated for ' + name;
  }

  Future<String> _getTrackingPreview() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    if (!user.hasChild('bills')) {
      return 'Add some bills to your tracking page!';
    }

    DataSnapshot bills = await userRef.child('bills').get();
    Map<String, dynamic> billsMap = bills.value as Map<String, dynamic>;
    String title = '', duedate = '';
    billsMap.forEach((key, value) {
      title = value['title'].toString();
      duedate = value['duedate'].toString();
    });

    return title + ' is due on ' + duedate;
  }

  Future<String> _getNotifPreview() async {
    DataSnapshot notifState = await reference
        .child('users/${currentUser?.uid}/notifications/state')
        .get();
    if (notifState.value == 1) {
      return 'You have new notifications!';
    } else {
      return 'You can view notifications here.';
    }
  }

  Future<String> _getProfilePreview() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    if (!user.hasChild('name')) {
      return 'Your Profile';
    } else {
      DataSnapshot name = await userRef.child('name').get();
      String username = name.value as String;
      return username + "'s Profile";
    }
  }

  Future<BudgetPieChart> _getBudgetPreview() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    DatabaseReference budgetRef =
        reference.child('users/${currentUser?.uid}/budgets/Default/budgetMap');
    DataSnapshot budget = await budgetRef.get();
    Map<String, dynamic> budgetData = budget.value as Map<String, dynamic>;
    Map<String, double> budgetMap = {};
    budgetData.forEach((key, value) {
      if (value is double) {
        budgetMap[key] = value;
      } else if (value is int) {
        budgetMap[key] = value.toDouble();
      } else if (value is String) {
        budgetMap[key] = double.tryParse(value) ?? 0.0;
      }
    });
    return BudgetPieChart(
      budgetMap: budgetMap,
      valuesAdded: budgetMap.isNotEmpty,
      colorList: greenColorList,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? url = currentUser!.photoURL;
    return Scaffold(
        appBar: const FFAppBar(),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfilePictureUpload(profileUrl: url as String, dash: true),
                    Text(
                      'Welcome, ${currentUser?.displayName}!',
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder(
                        future: _getBudgetPreview(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            print('error: ${snapshot.error}');
                          }
                          return Container(
                            child: snapshot.data,
                          );
                        }),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/investments');
                          },
                          child: const Text('Go to Investment Page'),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                          child: const Text('Go to Budget Dashboard Page'),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/tracking');
                          },
                          child: const Text('Go to Bill Tracking Page'),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/credit_card');
                          },
                          child: const Text('Go to Credit Card Page'),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                          child: const Text("Go to Notification Page"),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          child: const Text("Go to Profile Page"),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/locations');
                          },
                          child: const Text("Go to Locations Page"),
                        ),
                        const SizedBox(height: 16), //spacing
                        ElevatedButton(
                          style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text("Sign Out"),
                        ),
                        const SizedBox(height: 16), //spacing
                      ],
                    ),
                  ],
                )
              ],
            )));
  }
}
