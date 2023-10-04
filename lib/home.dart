import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final databaseReference = FirebaseDatabase.instance.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final _formKey = GlobalKey<FormState>();

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
        title: const Text('Your Homepage'),
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
              onPressed: () {
                Navigator.pushNamed(context, '/investments');
              },
              child: const Text('Go to Investment Page'),
            ),
            const SizedBox(height: 16), //spacing
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tracking');
              },
              child: const Text('Go to Tracking Page'),
            ),
            const SizedBox(height: 16), //spacing
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text("Go to Profile Page"),
            )
          ],
        ),
      ),
    );
  }
}
