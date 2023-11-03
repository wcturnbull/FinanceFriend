import 'package:financefriend/budget_tracking.dart';
import 'package:financefriend/create_account.dart';
import 'package:financefriend/graph_page.dart';
import 'package:financefriend/home.dart';
import 'package:financefriend/location.dart';
import 'package:financefriend/profile.dart';
import 'package:financefriend/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'investment_page.dart'; // Import the InvestmentPage
import 'tracking.dart'; // Import the TrackingPage
import 'credit_card.dart'; // Import the CreditCardPage
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_state.dart'; // new
import 'location.dart';
import 'dart:js' as js;

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final userRef = reference.child('users/${currentUser?.uid}');
final userNotificationsReference = userRef.child('notifications');
final currentUser = FirebaseAuth.instance.currentUser;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = ApplicationState();

    String startRoute = '/login';
    if (appState.loggedIn) {
      startRoute = '/home';
    }

    WidgetsFlutterBinding.ensureInitialized();

    return MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              primary: Colors.green,
              secondary: Color(int.parse("#1c6c0e".substring(1, 7), radix: 16) +
                  0xFF0000000)),
          useMaterial3: true,
        ),
        initialRoute: startRoute,
        routes: {
          '/login': (context) => Login(
                appState: appState,
              ),
          '/create_account': (context) => CreateAccount(appState: appState),
          '/investments': (context) => InvestmentPage(),
          '/tracking': (context) => const TrackingPage(),
          '/credit_card': (context) => CreditCardPage(),
          '/home': (context) => const HomePage(),
          '/dashboard': (context) => BudgetTracking(),
          '/profile': (context) => const Profile(),
          '/locations': (context) => const LocationPage(),
          '/notifications': (context) => const NotificationsPage(),
        });
  }
}
