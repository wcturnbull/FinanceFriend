import 'package:flutter/material.dart';
import 'dart:html' as html;

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.title});

  final String title;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
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
