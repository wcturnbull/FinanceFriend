
import 'dart:async';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

void _openRequestDialog(BuildContext context, String friendName) async {
  //Opens popup window allowing user to request or view a friend's financials
  bool budgetAccess = false;
  bool calendarAccess = false;
  String userName = currentUser?.displayName as String;
  String? friendUid = await getUidFromName(friendName);
  DataSnapshot user = await reference.child('users/$friendUid').get();
  if (user.hasChild('settings') &&
      user.child('settings').hasChild('permissions')) {
    DataSnapshot perms = await reference
        .child('users/$friendUid/settings/permissions/$userName')
        .get();
    Map<String, dynamic> permsMap = perms.value as Map<String, dynamic>;
    permsMap.forEach((key, value) {
      if (key == 'budgets') budgetAccess = value;
      if (key == 'calendar') calendarAccess = value;
    });
  }
  // ignore: use_build_context_synchronously
  showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            content: Stack(children: <Widget>[
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
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "View $friendName's financial information",
                      style: const TextStyle(fontSize: 20),
                    )),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                        child: Text(
                            budgetAccess ? 'View Budgets' : 'Request Budgets'),
                        onPressed: () {
                          if (budgetAccess) {
                            _viewBudgets(context, friendName);
                          } else {
                            _sendBudgetRequest(context, friendName);
                          }
                        })),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                        child: Text(calendarAccess
                            ? 'View Bill Calendar'
                            : 'Request Bill Calendar'),
                        onPressed: () {
                          if (calendarAccess) {
                            _viewCalendar(context, friendName);
                          } else {
                            _sendCalendarRequest(context, friendName);
                          }
                        })),
              ])),
            ]),
          ));
}

void _sendBudgetRequest(BuildContext context, String friendName) async {
  //Sends a request via notification to view a friend's budgets
  try {
    String userName = currentUser?.displayName as String;
    String? friendUid = await getUidFromName(friendName);
    DatabaseReference notifRef =
        reference.child('users/$friendUid/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Budgets',
      'note': 'Your friend $userName would like to view your budgets.',
    });
    notifRef.child('state').set(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Budget request sent successfully!',
        ),
      ),
    );
  } catch (error) {
    print(error);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Budget request failed to send due to an error.',
        ),
      ),
    );
  }
}

void _sendCalendarRequest(BuildContext context, String friendName) async {
  //Sends a request via notification to view a friend's bill tracking calendar
  try {
    String userName = currentUser?.displayName as String;
    String? friendUid = await getUidFromName(friendName);
    DatabaseReference notifRef =
        reference.child('users/$friendUid/notifications');
    DatabaseReference newNotif = notifRef.push();
    newNotif.set({
      'title': 'Request to View Calendar',
      'note': 'Your friend $userName would like to view your bill calendar.',
    });
    notifRef.child('state').set(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calendar request sent successfully!',
        ),
      ),
    );
  } catch (error) {
    print(error);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calendar request failed to send due to an error.',
        ),
      ),
    );
  }
}

void _viewBudgets(BuildContext context, String friendName) async {
  //Opens a popup window containing a friend's budgets
  String? friendUid = await getUidFromName(friendName);
  // ignore: use_build_context_synchronously
  showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            content: Stack(children: <Widget>[
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
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "$friendName's Budgets",
                      style: const TextStyle(fontSize: 24),
                    )),
                FutureBuilder(
                    future: reference.child('users/$friendUid/budgets').get(),
                    builder: (context, snapshot) {
                      if (snapshot.data != null &&
                          snapshot.data?.value != null) {
                        Map<String, dynamic> results =
                            snapshot.data?.value as Map<String, dynamic>;
                        List<Map<String, dynamic>> budgets = [];
                        results.forEach((key, value) {
                          budgets.add({
                            'budgetName': value['budgetName'].toString(),
                            'budgetMap': value['budgetMap'],
                          });
                        });
                        if (budgets.length != 0) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.green,
                              ),
                              columnSpacing: 30,
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Items')),
                              ],
                              rows: List.generate(
                                budgets.length,
                                (index) => _getBudgetRow(
                                  index,
                                  budgets[index],
                                ),
                              ),
                              showBottomBorder: true,
                            ),
                          );
                        } else {
                          return const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('This user has no budgets'),
                              ),
                            ],
                          );
                        }
                      } else {
                        return const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('This user has no budgets'),
                            ),
                          ],
                        );
                      }
                    }),
              ])),
            ]),
          ));
}

DataRow _getBudgetRow(index, data) {
  //Used to display budgets in a table format
  String budgetMap = '';
  data['budgetMap'].forEach((key, value) {
    budgetMap += '$key: \$$value, ';
  });
  budgetMap = budgetMap.substring(0, budgetMap.lastIndexOf(', '));
  return DataRow(
    cells: <DataCell>[
      DataCell(Text(data['budgetName'])),
      DataCell(Text(budgetMap)),
    ],
  );
}

void _viewCalendar(context, friendName) async {
  //Opens a popup window containing a friend's budgets
  String? friendUid = await getUidFromName(friendName);
  showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            content: Stack(children: <Widget>[
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
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "$friendName's Bill Calendar",
                      style: const TextStyle(fontSize: 24),
                    )),
                FutureBuilder(
                    future: reference.child('users/$friendUid/bills').get(),
                    builder: (context, snapshot) {
                      if (snapshot.data != null &&
                          snapshot.data?.value != null) {
                        Map<String, dynamic> results =
                            snapshot.data?.value as Map<String, dynamic>;
                        List<Map<String, String>> bills = [];
                        results.forEach((key, value) {
                          bills.add({
                            'title': value['title'].toString(),
                            'amount': value['amount'].toString(),
                            'duedate': value['duedate'].toString(),
                          });
                        });
                        if (bills.length != 0) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.green,
                              ),
                              columnSpacing: 30,
                              columns: const [
                                DataColumn(label: Text('Title')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Due Date')),
                              ],
                              rows: List.generate(
                                bills.length,
                                (index) => _getBillRow(
                                  index,
                                  bills[index],
                                ),
                              ),
                              showBottomBorder: true,
                            ),
                          );
                        } else {
                          return const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('This user has no bills'),
                              ),
                            ],
                          );
                        }
                      } else {
                        return const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('This user has no bills'),
                            ),
                          ],
                        );
                      }
                    }),
              ])),
            ]),
          ));
}

DataRow _getBillRow(index, data) {
  //Used to display bills in a table format
  return DataRow(
    cells: <DataCell>[
      DataCell(Text(data['title'])),
      DataCell(Text(data['amount'])),
      DataCell(Text(data['duedate'])),
    ],
  );
}
