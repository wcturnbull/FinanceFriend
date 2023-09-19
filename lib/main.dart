import 'package:financefriend/tracking.dart';
import 'package:flutter/material.dart';
import 'investment_page.dart'; // Import the InvestmentPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Finance Friend'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _goToInvestmentPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            InvestmentPage(), // Navigate to the InvestmentPage
      ),
    );
  }

  void _navigateToTrackingPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrackingPage(), // Navigate to the InvestmentPage
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _goToInvestmentPage, // Call the navigation function
              child: Text('Go to Investment Page'),
            ),
            ElevatedButton(
              onPressed:
                  _navigateToTrackingPage, // Call the navigation function
              child: Text('Go to TrackingPage'),
            ),
          ],
        ),
      ),
    );
  }
}
