import 'package:financefriend/ff_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'profile_picture_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    final url = currentUser?.photoURL as String;

    return Scaffold(
        appBar: const FFAppBar(),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 600,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfilePictureUpload(profileUrl: url),
                        Text('${currentUser!.displayName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 48,
                                color: Colors.white))
                      ],
                    ),
                    const Field(label: 'Bio'),
                    const Field(label: 'Email'),
                    const Field(label: 'Password'),
                    const GoalsList(),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ],
          )),
        ));
  }
}

class GoalsList extends StatefulWidget {
  const GoalsList({super.key});

  @override
  State<GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends State<GoalsList> {
  final TextEditingController controller = TextEditingController();
  List<String> goalChips = [];

  @override
  void initState() {
    super.initState();
    initializeGoalChips();
  }

  void initializeGoalChips() async {
    print('initializing goalChips: ${goalChips.toString()}');
    final userGoalsReference =
        reference.child('users/${currentUser?.uid}/goals');
    try {
      final DataSnapshot goalsSnapshot = await userGoalsReference.get();

      if (goalsSnapshot.exists) {
        List<dynamic>? goalsList = goalsSnapshot.value as List?;
        for (final goal in goalsList!) {
          if (goal is String) {
            setState(() {
              goalChips.add(goal);
            });
          }
        }
      }
    } catch (e) {
      print('Error initializing goalChips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: goalChips
                .map(
                  (goal) => Chip(
                    label: Text(goal),
                    onDeleted: () {
                      setState(() {
                        goalChips.remove(goal);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Add a Spending Goal',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final typedGoal = controller.text.trim();
                  if (typedGoal.isNotEmpty && !goalChips.contains(typedGoal)) {
                    setState(() {
                      goalChips.add(typedGoal);
                      controller.clear();
                    });
                  }
                },
              ),
            ),
          ),
        ),
        Center(
          child: ElevatedButton(
              onPressed: () {
                reference
                    .child('users/${currentUser?.uid}/goals')
                    .set(goalChips);
              },
              child: const Text('Save Goals')),
        )
      ],
    );
  }
}

class Field extends StatefulWidget {
  const Field({super.key, required this.label});

  final String label;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late TextEditingController controller;
  String currentText = '';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    if (widget.label == 'Bio') {
      reference
          .child('users/${currentUser?.uid}/bio')
          .onValue
          .listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null) {
          setState(() {
            currentText = data.toString();
            controller.text = currentText;
          });
        }
      });
    } else if (widget.label == 'Email') {
      setState(() {
        currentText = currentUser!.email!;
        controller.text = currentText;
      });
    } else {
      setState(() {
        controller.text = currentText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 10.0),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Enter new ${widget.label}',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.update),
                  onPressed: () async {
                    switch (widget.label) {
                      case 'Email':
                        currentUser
                            ?.verifyBeforeUpdateEmail(controller.text)
                            .then((result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Check your Email to Verify')));
                        }).catchError((error) {
                          print(error.toString());
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Update Failed')));
                        });
                        Navigator.pushNamed(context, '/login');
                        break;
                      case 'Password':
                        try {
                          currentUser?.updatePassword(controller.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Password Updated')));
                          Navigator.pushNamed(context, '/login');
                        } on Error {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Update Failed')));
                        }
                        break;
                      case 'Bio':
                        reference
                            .child('users/${currentUser?.uid}/bio')
                            .set(controller.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bio Updated')));
                        break;
                    }
                  },
                )),
          ),
        ),
      ),
    ]);
  }
}
