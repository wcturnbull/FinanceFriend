import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:financefriend/budget_tracking_widgets/budget_colors.dart';
import 'package:financefriend/credit_card.dart';
import 'package:financefriend/ff_appbar.dart';
import 'package:financefriend/globals.dart';
import 'package:financefriend/investment_page.dart';
import 'package:financefriend/location.dart';
import 'package:financefriend/notifications.dart';
import 'package:financefriend/profile.dart';
import 'package:financefriend/profile_picture_widget.dart';
import 'package:financefriend/social_hub_widgets/social_page_widget.dart';
import 'package:financefriend/tracking.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:financefriend/budget_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';
import 'dart:js' as js;

import 'package:pie_chart/pie_chart.dart';

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
  User? user = currentUser;

  @override
  void initState() {
    super.initState();
    // Set up a listener for authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? updatedUser) {
      setState(() {
        user = updatedUser;
      });

      if (user != null) {
        // Fetch and update user-specific data here
        _fetchUserData();
      }
    });
  }

  // Add this function to fetch and update user-specific data
  Future<void> _fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    // Update or refresh data based on the new user's information
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    final budgetsRef = reference.child('users/${currentUser?.uid}/budgets');

    DatabaseEvent event = await budgetsRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<String, dynamic> budgetData = snapshot.value as Map<String, dynamic>;
      List<String> budgetKeys = budgetData.keys.toList();
    }
  }

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

  Future<Widget> _getBudgetPreview() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    DataSnapshot user = await userRef.get();

    final budgetsRef = reference.child('users/${currentUser?.uid}/budgets');

    DatabaseEvent event = await budgetsRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<String, dynamic> budgetData = snapshot.value as Map<String, dynamic>;
      List<String> budgetKeys = budgetData.keys.toList();

      if (budgetKeys.isNotEmpty) {
        List<Widget> budgetWidgets = [];
        budgetWidgets.add(SizedBox(height: 10));
        budgetWidgets.add(Text("Budgets:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)));
        budgetWidgets.add(SizedBox(height: 10));

        for (String budgetKey in budgetKeys) {
          Budget currBudget = await getBudgetFromFirebaseByName(budgetKey);

          budgetWidgets.add(
            Column(
              children: [
                const SizedBox(height: 20),
                Row(children: [
                  const SizedBox(width: 20),
                  PieChart(
                    dataMap: currBudget.budgetMap,
                    colorList: currBudget.colorList,
                    chartRadius: 100,
                    chartType: ChartType.ring,
                    animationDuration: const Duration(milliseconds: 800),
                    ringStrokeWidth: 30,
                    chartValuesOptions:
                        const ChartValuesOptions(showChartValues: false),
                    centerText: budgetKey,
                  ),
                  const SizedBox(width: 20),
                ]),
                const SizedBox(
                    height: 20), // Add spacing between budget previews
              ],
            ),
          );
        }

        return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2.0, // Adjust the border width as needed
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            height: 400,
            width: 350,
            margin: const EdgeInsets.all(50),
            child: SingleChildScrollView(
                child: Column(
              children: budgetWidgets,
            )));
      }
    }

    // If there are no budgets or any other condition that prevents showing them
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2.0, // Adjust the border width as needed
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        height: 400,
        width: 350,
        margin: const EdgeInsets.all(50),
        child: SingleChildScrollView(
            child: Column(children: [
          SizedBox(height: 10),
          Text("Budgets:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          SizedBox(height: 150),
          Text("Click \"Go to Budget Dashboard\" to add Budgets"),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser != null) {
      final String? name = currentUser?.displayName;
      final String? url = currentUser?.photoURL;
      return Scaffold(
          appBar: FFAppBar(),
          body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfilePictureUpload(profileUrl: url ?? '', dash: true),
                      Text(
                        'Welcome, $name!',
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
                          /*
                        ElevatedButton(
                          style: const ButtonStyle(
                            fixedSize:
                                MaterialStatePropertyAll(Size(300.0, 50.0)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                  return InvestmentPage(); // Replace with your actual page widget
                                },
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  const duration = Duration(
                                      milliseconds:
                                          1000); // Adjust the duration here

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  var offsetAnimation = animation.drive(tween);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(
                                    milliseconds:
                                        1000), // Adjust the duration here
                              ),
                            );
                          },
                          child: const Text('Go to Investment Page'),
                        ), */
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return InvestmentPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/investments');
                              }
                            },
                            child: const Text('Go to Investment Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return BudgetTracking(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/dashboard');
                              }
                            },
                            child: const Text('Go to Budget Dashboard Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return TrackingPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/tracking');
                              }
                            },
                            child: const Text('Go to Bill Tracking Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return CreditCardPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/credit_card');
                              }
                            },
                            child: const Text('Go to Credit Card Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return NotificationsPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/notifications');
                              }
                            },
                            child: const Text('Go to Notification Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return Profile(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/profile');
                              }
                            },
                            child: const Text('Go to Profile Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return LocationPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/locations');
                              }
                            },
                            child: const Text('Go to Locations Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                            style: const ButtonStyle(
                              fixedSize:
                                  MaterialStatePropertyAll(Size(300.0, 50.0)),
                            ),
                            onPressed: () {
                              if (seeTransitions) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return SocialPage(); // Replace with your actual page widget
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeInOut;
                                      const duration = Duration(
                                          milliseconds:
                                              2000); // Adjust the duration here

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      var opacityAnimation =
                                          animation.drive(tween);

                                      return FadeTransition(
                                        opacity: opacityAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                        milliseconds:
                                            2000), // Adjust the duration here
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/social');
                              }
                            },
                            child: const Text('Go to Social Page'),
                          ),
                          const SizedBox(height: 16), //spacing
                          ElevatedButton(
                              child: Text("Sign Out"),
                              style: const ButtonStyle(
                                fixedSize:
                                    MaterialStatePropertyAll(Size(300.0, 50.0)),
                              ),
                              onPressed: () async {
                                try {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (route) => false);
                                  await FirebaseAuth.instance.signOut();
                                } catch (e) {
                                  // Handle sign-out errors, if any
                                  print('Error signing out: $e');
                                }
                              }),
                        ],
                      )
                    ],
                  )
                ],
              )));
    } else {
      return Scaffold(body: Text("Empty"));
    }
  }
}

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

Future<String> getProfilePictureUrl(String name) async {
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
