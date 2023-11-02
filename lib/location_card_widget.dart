import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final userLocationReference =
    reference.child('users/${currentUser?.uid}/locations');
final currentUser = FirebaseAuth.instance.currentUser;

class LocationCard extends StatefulWidget {
  final String locationName;
  final String locationAddress;
  final String date;

  LocationCard(
      {required this.date,
      required this.locationName,
      required this.locationAddress});

  @override
  _LocationCardState createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  final _formKey = GlobalKey<FormState>();
  String dropdownValue1 = 'Select a Budget';
  String dropdownValue2 = 'Select a Category';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.locationName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.locationAddress,
              style: TextStyle(fontSize: 16),
            ),
            Text(
              widget.date,
              style: TextStyle(fontSize: 16),
            ),
            Form(
              key: _formKey,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Enter a number'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  DropdownButton<String>(
                    value: dropdownValue1,
                    items: <String>['Option 1', 'Option 2', 'Option 3']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {},
                  ),
                  DropdownButton<String>(
                    value: dropdownValue2,
                    onChanged: (String? value) {},
                    items: <String>['Option 1', 'Option 2', 'Option 3']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}