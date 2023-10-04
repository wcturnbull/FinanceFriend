import 'package:flutter/material.dart';

class InvestmentPage extends StatelessWidget {
  const InvestmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Page'),
      ),
      body: const Center(
        child: Text(
          'This is the Investment Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
