import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController billTitleController = TextEditingController();
  final TextEditingController billDataController = TextEditingController();
  final TextEditingController billDateController = TextEditingController();

  void _writeBill(String title, String note, String duedate) {
    try {
      DatabaseReference newBill = reference.child('users/${currentUser?.uid}/bills').push();
      newBill.set({
        'title': title,
        'note': note,
        'duedate': duedate,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill added successfully! Refresh to update page.'),
        ),
      );
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add bill.'),
        ),
      );
    }

  }

  void _deleteBill(String id) {
    try {
      DatabaseReference billsRef = reference.child('users/${currentUser?.uid}/bills');
      billsRef.child(id).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill deleted succesfully! Refresh to update page.'),
        ),
      );
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete bill.'),
        ),
      );
    }
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => HomePage(),
    ));
  }

  List<Map<String, String>> results = [];
  DataRow _getDataRow(index, data) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(data['title'])),
        DataCell(Text(data['note'])),
        DataCell(Text(data['duedate'])),
        DataCell(IconButton(icon: Image.asset('images/DeleteButton.png'), onPressed: () => _deleteBill(data['id']),)),
      ],
    );
  }

  Future _fetchBills() async {
    DatabaseReference userRef = reference.child('users/${currentUser?.uid}');
    
    DataSnapshot user = await userRef.get();
    if(!user.hasChild('bills')) {
      return [{'title': '', 'note': '', 'duedate': ''}];
    }

    DataSnapshot bills = await userRef.child('bills').get();
    Map<String, dynamic> billsMap = bills.value as Map<String, dynamic>;
    results = [];
    billsMap.forEach((key, value) {
      results.add({'id': key.toString(), 'title': value['title'].toString(), 'note': value['note'].toString(), 'duedate': value['duedate'].toString()});
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          leading: 
            IconButton(
              icon: Image.asset('images/FFLogo.png'),
              onPressed: () => {
                Navigator.pushNamed(context, '/home')
              },
            ),
          title: Text('Bill Tracking Page'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bills', style: TextStyle(fontSize: 32)),
              RefreshIndicator(onRefresh: () async {
                return await _fetchBills();
              },
                child: FutureBuilder(
                  future: _fetchBills(),
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
                              DataColumn(label: Text('Due Date')),
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
                  },
                ),
              ),
              ElevatedButton(
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
                                      child: Text('Please input bill data that you would like us to keep track of.', style: TextStyle(fontSize: 20))
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(children: [
                                        Text('Bill Title: ', style: TextStyle(fontSize: 14)),
                                        Expanded(
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              hintText: 'Enter a title to identify the bill',
                                            ),
                                            controller: billTitleController,
                                          ),
                                        ),
                                      ],)
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(children: [
                                        Text('Bill Data: ', style: TextStyle(fontSize: 14)),
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              hintText: "Enter some data that you'd like to remember about the bill",
                                            ),
                                            controller: billDataController,
                                          ),
                                        ),
                                      ],)
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(children: [
                                        Text('Bill Due Date: ', style: TextStyle(fontSize: 14)),
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              hintText: 'Use MM/DD/YYYY',
                                            ),
                                            controller: billDateController,
                                          ),
                                        ),
                                      ],)
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            child: const Text('Submit'),
                                            onPressed: () {
                                              String billTitle = billTitleController.text;
                                              String billData = billDataController.text;
                                              String billDate = billDateController.text;
                                              if (billTitle.isEmpty || billDate.isEmpty || billDate.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Failed to add bill. Please ensure that all fields are filled in.'),
                                                  ),
                                                );
                                              } else {
                                                _writeBill(billTitle, billData, billDate);
                                                Navigator.of(context).pop();
                                                //update page
                                              }
                                            },
                                          ),
                                          ElevatedButton(
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],)
                                    )
                                  ],
                                ),
                              ),
                            ],
                      )
                    )
                  );
                },
                child: const Text('Add Bill'),
              )
            ],)
        ),
      ),
    );
  }
}