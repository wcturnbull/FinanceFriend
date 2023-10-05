import 'package:flutter/material.dart';
import 'ff_appbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FFAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/investments');
              }, // Call the navigation function
              child: const Text('Go to Investment Page'),
            ),
            const SizedBox(height: 16), // Add some spacing
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tracking');
              },
              child: const Text('Tracking Page'),
            ),
            SizedBox(height: 16), // Add some spacing
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: Text('Open Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
