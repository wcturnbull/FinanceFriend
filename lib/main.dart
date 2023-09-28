import 'package:financefriend/create_account.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // new
import 'package:go_router/go_router.dart';               // new
import 'package:provider/provider.dart';                 // new
import 'app_state.dart';                                 // new

Future<void> main() async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  WidgetsFlutterBinding.ensureInitialized();

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const MyApp()),
  ));
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(102, 203, 19, 1), 
          primary: const Color.fromRGBO(102, 203, 19, 1),
          secondary: const Color.fromRGBO(16, 178, 76, 1)),
        useMaterial3: true,
      ),
      home: const Login(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/create_account':(context) => const CreateAccount(),
      }
    );
  }
}