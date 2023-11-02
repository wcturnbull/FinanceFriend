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

class FFAppBar extends StatefulWidget implements PreferredSizeWidget{
  const FFAppBar({super.key});

  @override
  State<FFAppBar> createState() => _FFAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FFAppBarState extends State<FFAppBar> {
  bool _allNotifs = true;
  bool _billNotifs = true;

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
      reference.child('users/${currentUser?.uid}').child('landing_page').set(path);
    } catch (error) {
      print("Error setting landing page: $error");
    }
  }

  void _getAllNotifs() async {
    try {
      DatabaseReference settingsRef = reference.child('users/${currentUser?.uid}').child('settings');
      DataSnapshot settings = await settingsRef.get();
      if (!settings.hasChild('allNotifs')) {
        settingsRef.child('allNotifs').set(1);
      } else {
        setState(() {
          _allNotifs = (settings.child('allNotifs').value == 1);
        });
      }
      if (!settings.hasChild('billNotifs')) {
        settingsRef.child('billNotifs').set(1);
      } else {
        setState(() {
          _billNotifs = (settings.child('billNotifs').value == 1);
        });
      }
    } catch (error) {
      print("Error getting notifications settings: $error");
    }
  }

  void _writeNotifSettings() {
    DatabaseReference settingsRef = reference.child('users/${currentUser?.uid}').child('settings');
    settingsRef.child('allNotifs').set(_allNotifs ? 1 : 0);
    settingsRef.child('billNotifs').set(_billNotifs ? 1 : 0);
  }

  void _openNotifsSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Stack(children: <Widget>[
          Positioned(
            right: -40,
            top: -40,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: 20),
              )),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('All Notifications'),
                        Switch(
                          value: _allNotifs, 
                          onChanged: (bool newValue) {
                            setState(() {
                              _allNotifs = newValue;
                            });
                          },
                        ),
                      ],
                  ));
                }
              ),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bill Tracking Notifications'),
                        Switch(
                          value: _billNotifs, 
                          onChanged: (bool newValue) {
                            setState(() {
                              _billNotifs = newValue;
                            });
                          },
                        ),
                      ],
                  ));
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () {
                        _writeNotifSettings();
                        Navigator.of(context).pop();
                      }
                    ),
                  ],
              )),
          ]),
        ]),
    ));
  }

  void _openAccountSaver(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Stack(children: <Widget>[
          Positioned(
            right: -40,
            top: -40,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                    'Are you sure that you would like to delete your account?',
                    style: TextStyle(fontSize: 20)
            )),
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                    'This action is permanent and cannot be reversed.',
                    style: TextStyle(fontSize: 20)
            )),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text(
                          'Delete Account'),
                      onPressed: () {
                        _deleteUser();
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context,'/login');
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )),
          ])
        ]),
      ));
  }

  void _openLandingChanger(BuildContext context) async {
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
              child:
                  const CircleAvatar(
                backgroundColor:
                    Colors.red,
                child: Icon(
                    Icons.close),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Choose which page you want to see when you login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                  )),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Default Homepage'),
                  onPressed: () {
                    _setLandingPage('/home');
                    Navigator.of(context).pop();
                  }),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Investments Page'),
                  onPressed: () {
                    _setLandingPage('/investments');
                    Navigator.of(context).pop();
                  }),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Bill Tracking Page'),
                  onPressed: () {
                    _setLandingPage('/tracking');
                    Navigator.of(context).pop();
                  }),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Budget Page'),
                  onPressed: () {
                    _setLandingPage('/budgets');
                    Navigator.of(context).pop();
                  }),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Profile Page'),
                  onPressed: () {
                    _setLandingPage('/profile');
                    Navigator.of(context).pop();
                  }),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  child: const Text('Graph Page'),
                  onPressed: () {
                    _setLandingPage('/dashboard');
                    Navigator.of(context).pop();
                  }),
              ),
            ])
        ])));
  }

  void _openSettings(BuildContext context) {
    showDialog<void>(
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ))),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      child: const Text('Set Custom Homepage'),
                      onPressed: () => _openLandingChanger(context)
                    )),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      child: const Text('Notifications Settings'),
                      onPressed: () {
                        _getAllNotifs();
                        _openNotifsSettings(context);
                      }
                    )),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    child: const Text('Delete Account'),
                    onPressed: () => _openAccountSaver(context),
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
          ],
        )
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: IconButton(
        icon: Image.asset('images/FFLogo.png'),
        onPressed: () => Navigator.pushNamed(context, '/home'),
      ),
      title: const Text(
        'Finance Friend',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 44,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          icon: Image.asset('images/Settings.png'),
          onPressed: () => _openSettings(context),
        ),
      ],
    );
  }
}