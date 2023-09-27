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
  final _formKey = GlobalKey<FormState>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Image.asset('settings.png'),
            onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Stack(
                      children: <Widget>[
                            Positioned(
                              right: -40,
                              top: -40,
                              child: InkResponse(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: const CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Stuff goes here to customize dashboard/delete or access account info', style: TextStyle(fontSize: 20))
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ElevatedButton(
                                      child: const Text('Exit'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                    )
                  )
                );
              },
          ),
        ],
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
          ],
        ),
      ),
    );
  }
}
