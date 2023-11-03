import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

String creditScoreStatus = ''; // Store the credit score status
String creditScoreAdvice = ''; // Store the credit score advice
//List Of Cards Spending Values
String wFargo = '\$315.56';
String boa = '\$318.78';
String chase = '\$315.56';
String discover = '\$318.78';
String cOne = '\$317.17';

class CreditCardPage extends StatefulWidget {
  @override
  _CreditCardPageState createState() => _CreditCardPageState();
}

class _CreditCardPageState extends State<CreditCardPage> {
  // Function to update the credit score status based on the score
  void updateCreditScoreStatus(int creditScore) {
    if (creditScore < 560) {
      creditScoreStatus = 'Bad';
      creditScoreAdvice =
          'Consider paying off outstanding debts and making on-time payments to improve your creditworthiness. Reducing credit card balances and addressing any delinquent accounts can help raise your score over time.';
    } else if (creditScore >= 560 && creditScore < 670) {
      creditScoreStatus = 'Fair';
      creditScoreAdvice =
          'Focus on reducing outstanding debts, making consistent, on-time payments, and avoiding new debt. Additionally, consider reviewing your credit report for errors and disputing any inaccuracies to help improve your credit score.';
    } else if (creditScore >= 670 && creditScore < 750) {
      creditScoreStatus = 'Good';
      creditScoreAdvice =
          'Aim to maintain your good credit by continuing to make on-time payments and avoiding excessive new debt. Additionally, consider diversifying your credit mix, which can have a positive impact on your credit score. Regularly monitor your credit report to ensure accuracy and address any discrepancies promptly.';
    } else if (creditScore >= 750) {
      creditScoreStatus = 'Excellent';
      creditScoreAdvice =
          'Explore opportunities to optimize your credit mix and consider leveraging your strong credit profile to secure favorable financial terms and benefits, such as lower interest rates and premium credit card offers. Regularly monitor your credit report to ensure accuracy and safeguard your exceptional credit status.';
    } else {
      creditScoreStatus = 'Invalid Score';
      creditScoreAdvice = 'Please enter a valid credit score between 0 and 850';
    }
    // Update the UI with the new credit score status
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CardSelectionDialog();
                  },
                );
              },
              child: Text('Select A Card'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CreditScoreInputDialog(updateCreditScoreStatus);
                  },
                );
              },
              child: Text('Tips'),
            ),
          ],
        ),
      ),
    );
  }
}

class CardSelectionDialog extends StatefulWidget {
  @override
  _CardSelectionDialogState createState() => _CardSelectionDialogState();
}

class _CardSelectionDialogState extends State<CardSelectionDialog> {
  String selectedCard = 'Wells Fargo Active Cash';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select a Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<String>(
            value: selectedCard,
            items: [
              'Wells Fargo Active Cash',
              'Bank of America Travel Rewards',
              'Chase Freedom Unlimited',
              'Discover it Cash Back',
              'Capital One QuickSilver',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedCard = newValue!;
              });
            },
          ),
          if (selectedCard.isNotEmpty) Text('Original Spending Total: \$322'),
          if (selectedCard == 'Wells Fargo Active Cash')
            Text('Spending With $selectedCard: $wFargo'),
          if (selectedCard == 'Wells Fargo Active Cash')
            Text('Money Saved: \$6.44'),
          if (selectedCard == 'Bank of America Travel Rewards')
            Text('Spending With $selectedCard: $boa'),
          if (selectedCard == 'Bank of America Travel Rewards')
            Text('Money Saved: \$3.22'),
          if (selectedCard == 'Chase Freedom Unlimited')
            Text('Spending With $selectedCard: $chase'),
          if (selectedCard == 'Chase Freedom Unlimited')
            Text('Money Saved: \$6.44'),
          if (selectedCard == 'Discover it Cash Back')
            Text('Spending With $selectedCard: $discover'),
          if (selectedCard == 'Discover it Cash Back')
            Text('Money Saved: \$3.22'),
          if (selectedCard == 'Capital One QuickSilver')
            Text('Spending With $selectedCard: $cOne'),
          if (selectedCard == 'Capital One QuickSilver')
            Text('Money Saved: \$4.83'),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            // Handle save button action here
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle close button action here
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}

class CreditScoreInputDialog extends StatefulWidget {
  final Function(int) onCreditScoreSaved;

  CreditScoreInputDialog(this.onCreditScoreSaved);

  @override
  _CreditScoreInputDialogState createState() => _CreditScoreInputDialogState();
}

class _CreditScoreInputDialogState extends State<CreditScoreInputDialog> {
  TextEditingController creditScoreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Credit Score'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: creditScoreController,
            decoration: InputDecoration(labelText: 'Credit Score'),
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            final creditScore = int.tryParse(creditScoreController.text) ?? 0;
            widget.onCreditScoreSaved(creditScore);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Credit Score: $creditScoreStatus - $creditScoreAdvice'),
                backgroundColor: Color.fromARGB(255, 59, 139, 61),
                duration: Duration(seconds: 100),
              ),
            );
          },
          child: Text('Save'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle close button action here
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}
