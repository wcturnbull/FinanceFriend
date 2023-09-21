import 'package:financefriend/graph_page.dart';
import 'package:flutter/material.dart';
import 'investment_page.dart'; // Import the InvestmentPage
import 'tracking.dart'; // Import the TrackingPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceFriend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Color(
                int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000)),
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

  void _navigateToTrackingPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingPage(title: widget.title),
    ));
  }

  void _navigateToGraphsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GraphPage(), // Navigate to the InvestmentPage
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(
            int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000),
        title: Text(widget.title),
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.bold,
            fontFamily: "Daddy Day"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _goToInvestmentPage, // Call the navigation function
              child: Text('Go to Investment Page'),
            ),
            SizedBox(height: 16), // Add some spacing
            ElevatedButton(
              onPressed: () {
                _navigateToTrackingPage(context);
              },
              child: Text('Tracking Page'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateToGraphsPage();
              },
              child: Text('Go to graphs page'),
            ),
          ],
        ),
      ),
    );
  }
}
