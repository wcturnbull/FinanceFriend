import 'package:flutter/material.dart';

class CreditCardPage extends StatefulWidget {
  @override
  _CreditCardPageState createState() => _CreditCardPageState();
}

class _CreditCardPageState extends State<CreditCardPage> {
  String creditScoreStatus = ''; // Store the credit score status

  // Function to update the credit score status based on the score
  void updateCreditScoreStatus(int creditScore) {
    if (creditScore < 560) {
      creditScoreStatus = 'Bad';
    } else if (creditScore >= 560 && creditScore < 670) {
      creditScoreStatus = 'Fair';
    } else if (creditScore >= 670 && creditScore < 750) {
      creditScoreStatus = 'Good';
    } else if (creditScore >= 750) {
      creditScoreStatus = 'Excellent';
    } else {
      creditScoreStatus = 'Invalid Score';
    }
    // Update the UI with the new credit score status
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Image.asset('images/FFLogo.png'),
          onPressed: () => Navigator.pushNamed(context, '/home'),
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
            SizedBox(height: 20),
            Text(
                'Credit Score: $creditScoreStatus'), // Display credit score status
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
