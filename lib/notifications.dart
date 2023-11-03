import 'package:flutter/material.dart';
import 'package:financefriend/ff_appbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_card_widget.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
  app: firebaseApp,
  databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/",
);
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  void _writeNotif(String title, String note) {
    try {
      DatabaseReference notifRef = reference.child('users/${currentUser?.uid}/notifications');
      DatabaseReference newNotif = notifRef.push();
      newNotif.set({
        'title': title,
        'note': note,
      });
      notifRef.child('state').set(1);
    } catch (error) {
      print(error);
    }
  }

  void _silenceNotifs() {
    try {
      DatabaseReference notifRef = reference.child('users/${currentUser?.uid}/notifications');
      notifRef.child('state').set(0);
    } catch (error) {
      print(error);
    }
  }

  void _deleteNotif(String id) async {
    try {
      DatabaseReference notifRef = reference.child('users/${currentUser?.uid}/notifications');
      notifRef.child(id).remove();
      DataSnapshot notifs = await notifRef.get();
      if (notifs.children.length <= 1) {
        notifRef.child('state').set(0);
      }
    } catch (error) {
      print(error);
    }
  }

  List<Map<String, String>> results = [];
  Future _fetchNotifs() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');

    DataSnapshot user = await userRef.get();
    if (!user.hasChild('notifications')) {
      return [
        {'title': '', 'note': ''}
      ];
    }

    DataSnapshot notifs = await userRef.child('notifications').get();
    Map<String, dynamic> notifsMap = notifs.value as Map<String, dynamic>;
    results = [];
    notifsMap.forEach((key, value) {
      if (key != 'state') {
        results.add({
          'id': key.toString(),
          'title': value['title'].toString(),
          'note': value['note'].toString(),
        });
      }
    });

    return results;
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
    return Scaffold(
      appBar: const FFAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 32)),
            FutureBuilder(
              future: _fetchNotifs(), 
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  results = snapshot.data;
                  if (snapshot.data.length != 0) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.green,
                        ),
                        columnSpacing: 30,
                        columns: [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Delete')),
                        ],
                        rows: List.generate(
                          results.length,
                          (index) => _getDataRow(
                            index,
                            results[index],
                          ),
                        ),
                        showBottomBorder: true,
                      ),
                    );
                  } else {
                    return const Row(
                      children: <Widget>[
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(),
                        ),
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No Data Found...'),
                        ),
                      ],
                    );
                  }
                } else {
                  return const Row(
                    children: <Widget>[
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No Data Found...'),
                      ),
                    ],
                  );
                }
              }
            ),
            ElevatedButton(
              onPressed: _silenceNotifs,
              child: const Text('Mark Notifications As Read'),
            ),
          ]),
      ),
    );
  }
}