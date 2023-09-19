import 'package:flutter/material.dart';
import 'dart:html' as html;

class TrackingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tracking'),
        ),
        body: Center(
          child: Text(
            'This is the tracking page',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}
