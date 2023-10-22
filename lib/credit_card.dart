import 'package:flutter/material.dart';

class CreditCardPage extends StatelessWidget {
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
  String selectedCard = 'Card 1';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select a Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<String>(
            value: selectedCard,
            items: ['Card 1', 'Card 2', 'Card 3'].map((String value) {
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
