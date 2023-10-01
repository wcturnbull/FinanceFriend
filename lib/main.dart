import 'package:financefriend/create_account.dart';
import 'package:financefriend/graph_page.dart';
import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'investment_page.dart'; // Import the InvestmentPage
import 'tracking.dart'; // Import the TrackingPage
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_state.dart'; // new

Future<void> main() async {
  final appState = ApplicationState();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Widget startWidget;
  if (appState.loggedIn) {
    startWidget = const HomePage();
  } else {
    startWidget = Login(appState: appState);
  }

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(102, 203, 19, 1),
              primary: const Color.fromRGBO(102, 203, 19, 1),
              secondary: const Color.fromRGBO(16, 178, 76, 1)),
          useMaterial3: true,
        ),
        home: startWidget,
        initialRoute: '/login',
        routes: {
          '/login': (context) => Login(
                appState: appState,
              ),
          '/create_account': (context) => CreateAccount(appState: appState),
          '/investments': (context) => InvestmentPage(),
          '/tracking': (context) => const TrackingPage(),
          '/dashboard': (context) => GraphPage(),
          '/home': (context) => const HomePage(),
        }),
  );
}
