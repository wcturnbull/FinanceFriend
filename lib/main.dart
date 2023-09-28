import 'package:financefriend/create_account.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_state.dart'; // new

Future<void> main() async {
  final appState = ApplicationState();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        home: Login(appState: appState),
        initialRoute: '/login',
        routes: {
          '/login': (context) => Login(appState: appState,),
          '/create_account': (context) => CreateAccount(appState: appState),
        }
    ),
  );
}
