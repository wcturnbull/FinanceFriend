import 'package:financefriend/create_account.dart';
import 'package:financefriend/graph_page.dart';
import 'package:financefriend/home.dart';
import 'package:financefriend/profile.dart';
import 'package:flutter/material.dart';
import 'investment_page.dart'; // Import the InvestmentPage
import 'tracking.dart'; // Import the TrackingPage
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_state.dart'; // new

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = ApplicationState();

    String startRoute = '/login';
    if (appState.loggedIn) {
      startRoute = '/home';
    }

    WidgetsFlutterBinding.ensureInitialized();

    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(102, 203, 19, 1),
              primary: const Color.fromRGBO(102, 203, 19, 1),
              secondary: const Color.fromRGBO(16, 178, 76, 1)),
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
          '/home': (context) => const HomePage(),
          '/dashboard': (context) => GraphPage(),
        });
  }
}
