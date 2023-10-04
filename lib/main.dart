import 'package:flutter/material.dart';
import 'investment_page.dart'; // Import the InvestmentPage
import 'tracking.dart'; // Import the TrackingPage
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final databaseReference = FirebaseDatabase.instance.ref();
final currentUser = FirebaseAuth.instance.currentUser;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Finance Friend'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  void _goToInvestmentPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            InvestmentPage(), // Navigate to the InvestmentPage
      ),
    );
  }

  void _navigateToTrackingPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingPage(title: widget.title),
    ));
  }

  Future<void> _deleteUser() async {
    try {
      DatabaseReference userRef = databaseReference.child('users/${currentUser?.uid}');
      await userRef.remove();
    } catch (error) {
      print("Error deleting user: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Image.asset('settings.png'),
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
                                    child: Text('Username/Name and other basic account info', style: TextStyle(fontSize: 20))
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Customization menu (allow user to change ordering of previews)', style: TextStyle(fontSize: 20))
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ElevatedButton(
                                      child: const Text('Delete Account'),
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
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Text('Are you sure that you want to delete your account?', style: TextStyle(fontSize: 20))
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Text('This action is permanent and cannot be reversed.', style: TextStyle(fontSize: 20))
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Row(children: [
                                                        ElevatedButton(
                                                          child: const Text('Delete Account'),
                                                          onPressed: () {
                                                            _deleteUser();
                                                            Navigator.of(context).pop();
                                                            Navigator.pushNamed(context, '/login');
                                                          },
                                                        ),
                                                        ElevatedButton(
                                                          child: const Text('Cancel'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                      ],
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      )
                                                    ),
                                                  ]
                                                )
                                              )
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
                    )
                  )
                );
              },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _goToInvestmentPage, // Call the navigation function
              child: Text('Go to Investment Page'),
            ),
            SizedBox(height: 16), // Add some spacing
            ElevatedButton(
              onPressed: () {
                _navigateToTrackingPage(context);
              },
              child: Text('Tracking Page'),
            ),
          ],
        ),
      ),
    );
  }
}
