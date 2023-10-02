import 'package:flutter/material.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tracking'),
        ),
        body: const Center(
          child: Text(
            'This is the tracking page',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}