import 'package:flutter/material.dart';

class CreditCardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Image.asset('images/FFLogo.png'),
          onPressed: () => {Navigator.pushNamed(context, '/home')},
        ),
        title: Text(
          'Credit Card Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Text('This is the Credit Card Page'),
      ),
    );
  }
}
