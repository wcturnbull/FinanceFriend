import 'package:flutter/material.dart';

class InvestmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investment Page'),
      ),
      body: Center(
        child: Text(
          'This is the Investment Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}