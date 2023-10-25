import 'package:flutter/material.dart';
import 'package:financefriend/ff_appbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
  app: firebaseApp,
  databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/",
);
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _writeNotif(String title, String note) {
    try {
      DatabaseReference newNotif = reference.child('users/${currentUser?.uid}/bills').push();
      newNotif.set({
        'title': title,
        'note': note,
      });
    } catch (error) {
      print(error);
    }
  }

  void _deleteNotif(String id) {
    try {
      DatabaseReference notifRef = reference.child('users/${currentUser?.uid}/notifications');
      notifRef.child(id).remove();
    } catch (error) {
      print(error);
    }
  }

  DataRow _getDataRow(index, data) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(data['title'])),
        DataCell(Text(data['note'])),
        DataCell(IconButton(
          icon: Image.asset('images/DeleteButton.png'),
          onPressed: () => _deleteNotif(data['id']),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: FFAppBar(),
        body: Center(
          child: ,
        ),
      )
    );
  }
}