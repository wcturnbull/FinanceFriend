import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_getInvestmentsPreview()),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/investments');
                  },
                  child: const Text('Go to Investment Page'),
                ),
              ],
            ),
            const SizedBox(height: 16), //spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder(
                    future: _getBudgetsPreview(),
                    builder: ((context, snapshot) {
                      String text = snapshot.data ?? '';
                      return Text(text);
                    })),
              ],
            ),
            const SizedBox(height: 16), //spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
            ),
            const SizedBox(height: 16), //spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(''),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                  child: const Text('Go to Graph Dashboard Page'),
                ),
              ],
            ),
            const SizedBox(height: 16), //spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  child: const Text("Go to Notification Page"),
                )
              ],
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
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
