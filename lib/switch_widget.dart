import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:js' as js;
import 'main.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final userRef = reference.child('users/${currentUser?.uid}');
final userNotificationsReference = userRef.child('notifications');
final currentUser = FirebaseAuth.instance.currentUser;

class SwitchWidget extends StatefulWidget {
  final String label;
  final String dbLocation;
  bool switched;
  bool all;

  SwitchWidget(
      {super.key,
      required this.label,
      required this.dbLocation,
      required this.switched,
      required this.all});

  @override
  _SwitchWidgetState createState() => _SwitchWidgetState();
}

class _SwitchWidgetState extends State<SwitchWidget> {
  Future<void> _selectTime(BuildContext context, TimeOfDay selectedTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        userNotificationsReference
            .child('notifTime')
            .set(selectedTime.format(context));
        showAlertAtTime();
      });
    }
  }

  Future<TimeOfDay> _getNotifTime() async {
    DataSnapshot notifTime =
        await userNotificationsReference.child('notifTime').get();
    TimeOfDay time = TimeOfDay.now();

    if (notifTime.exists) {
      DateFormat format = DateFormat('h:mm a');
      time = TimeOfDay.fromDateTime(format.parse(notifTime.value as String));
    }

    return time;
  }

  void showAlertAtTime() async {
    DataSnapshot notifTime =
        await userNotificationsReference.child('notifTime').get();

    DateFormat format = DateFormat('h:mm a');
    TimeOfDay timeOfDay =
        TimeOfDay.fromDateTime(format.parse(notifTime.value as String));
    DateTime time = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, timeOfDay.hour, timeOfDay.minute);

    print('Alert will ring in ${time.difference(DateTime.now())}');

    final Duration delay = time.difference(DateTime.now());
    js.context.callMethod('setTimeout', [
      js.allowInterop(() {
        showDialog(
          context: navigatorKey.currentState!.context,
          builder: (context) {
            return const AlertDialog(
              title: Text('Notification'),
              content: Text('Go enter your expenses into your location history!.'),
            );
          },
        );
      }),
      delay.inMilliseconds,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.label),
            Switch(
              value: widget.switched,
              onChanged: (bool value) {
                setState(() {
                  widget.switched = value;
                  reference
                      .child(
                          'users/${currentUser?.uid}/settings/${widget.dbLocation}')
                      .set(value);
                });
              },
            )
          ]),
          if (widget.dbLocation == 'locHistNotifs')
            if (widget.switched)
              FutureBuilder<TimeOfDay>(
                future: _getNotifTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Display a loading indicator while waiting for the result
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // Handle errors if needed
                    print('Error: ${snapshot.error}');
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Use the selected time from the snapshot data
                    final selectedTime = snapshot.data as TimeOfDay;

                    return ElevatedButton(
                      onPressed: () => _selectTime(context, selectedTime),
                      child: Text(
                          'Selected time: ${selectedTime.format(context)}'),
                    );
                  }
                },
              )
        ]));
  }
}
