import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final _formKey = GlobalKey<FormState>();

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

  Future<void> _deleteUser() async {
    try {
      FirebaseAuth.instance.currentUser?.delete();
      DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
      await userRef.remove();
    } catch (error) {
      print("Error deleting user: $error");
    }
  }

  void _setLandingPage(String path) async {
    try {
      reference
          .child('users/${currentUser?.uid}')
          .child('landing_page')
          .set(path);
    } catch (error) {
      print("Error setting landing page: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Your Homepage',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Image.asset('images/Settings.png'),
            onPressed: () async {
              await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                          content: Stack(
                        children: <Widget>[
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
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Settings',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ))),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ElevatedButton(
                                      child: const Text('Set Custom Homepage'),
                                      onPressed: () async {
                                        await showDialog<void>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                    content: Stack(
                                                        children: <Widget>[
                                                      Positioned(
                                                        right: -40,
                                                        top: -40,
                                                        child: InkResponse(
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const CircleAvatar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            child: Icon(
                                                                Icons.close),
                                                          ),
                                                        ),
                                                      ),
                                                      Form(
                                                          child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child: Text(
                                                                  'Choose which page you want to see when you login',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        20,
                                                                  )),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Default Homepage'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/home');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Investments Page'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/investments');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Bill Tracking Page'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/tracking');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Budget Page'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/budgets');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Profile Page'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/profile');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              child:
                                                                  ElevatedButton(
                                                                      child: const Text(
                                                                          'Graph Page'),
                                                                      onPressed:
                                                                          () {
                                                                        _setLandingPage(
                                                                            '/dashboard');
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }),
                                                            ),
                                                          ]))
                                                    ])));
                                      },
                                    )),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ElevatedButton(
                                    child: const Text('Delete Account'),
                                    onPressed: () async {
                                      await showDialog<void>(
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
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: Text(
                                                          'Are you sure that you would like to delete your account?',
                                                          style: TextStyle(
                                                              fontSize: 20))),
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: Text(
                                                          'This action is permanent and cannot be reversed.',
                                                          style: TextStyle(
                                                              fontSize: 20))),
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: Row(
                                                        children: [
                                                          ElevatedButton(
                                                            child: const Text(
                                                                'Delete Account'),
                                                            onPressed: () {
                                                              _deleteUser();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              Navigator
                                                                  .pushNamed(
                                                                      context,
                                                                      '/login');
                                                            },
                                                          ),
                                                          ElevatedButton(
                                                            child: const Text(
                                                                'Cancel'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ],
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                      )),
                                                ]))
                                          ]),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ElevatedButton(
                                    child: const Text('Close'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      )));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(_getInvestmentsPreview()),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/investments');
                  },
                  child: const Text('Go to Investment Page'),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            Row(
              children: <Widget>[
                FutureBuilder(
                    future: _getBudgetsPreview(),
                    builder: ((context, snapshot) {
                      String text = snapshot.data ?? '';
                      return Text(text);
                    })),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            Row(
              children: <Widget>[
                FutureBuilder(
                    future: _getTrackingPreview(),
                    builder: ((context, snapshot) {
                      String text = snapshot.data ?? '';
                      return Text(text);
                    })),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracking');
                  },
                  child: const Text('Go to Bill Tracking Page'),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            Row(
              children: <Widget>[
                Text(''),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                  child: const Text('Go to Graph Dashboard Page'),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            Row(
              children: <Widget>[
                Text(''),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/credit_card');
                  },
                  child: const Text('Go to Credit Card Page'),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            Row(
              children: <Widget>[
                FutureBuilder(
                    future: _getProfilePreview(),
                    builder: ((context, snapshot) {
                      String text = snapshot.data ?? '';
                      return Text(text);
                    })),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: const Text("Go to Profile Page"),
                ),
                
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            const SizedBox(height: 16), //spacing
            ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/locations');
                  },
                  child: const Text("Go to Locations Page"),
                ),
            const SizedBox(height: 16), //spacing
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
