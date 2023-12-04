import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final userBudgetsReference =
    reference.child('users/${currentUser?.uid}/budgets');
final currentUser = FirebaseAuth.instance.currentUser;
String selectedBudget = 'Select a Budget';
String selectedCategory = 'Select a Category';
TextEditingController expenseController = TextEditingController();

class LocationCard extends StatefulWidget {
  final String locationName;
  final String locationAddress;
  final String date;

  LocationCard(
      {required this.date,
      required this.locationName,
      required this.locationAddress});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  final _formKey = GlobalKey<FormState>();

  Future<void> submitExpense(final amount, String budget, String category,
      BuildContext context) async {
    if (budget == 'Select a Budget' || category == 'Select a Category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a budget and category')),
      );
    } else {
      double expenseAmount;
      try {
        print(
            'amount: $amount\n' + 'budget: $budget\n' + 'category: $category');
        expenseAmount = double.parse(amount);
        List<Expense> expense = [
          Expense(
              item: widget.locationName,
              price: expenseAmount,
              category: category,
              date: widget.date)
        ];
        List<Expense> currentExpenses = await getExpensesFromDB(budget);
        expense.addAll(currentExpenses);
        if (await saveExpensesToFirebase(budget, expense)) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense submitted successfully')));
          DatabaseReference locationsRef =
              reference.child('users/${currentUser?.uid}/locations');
          locationsRef.child('${widget.locationName}:${widget.date}').remove();
        }
        DatabaseReference notifRef =
            reference.child('users/${currentUser?.uid}/notifications');
        DataSnapshot notifSnap = await notifRef.get();
        Map<String, dynamic> notifsMap =
            notifSnap.value as Map<String, dynamic>;

        bool delete = false;
        String mapKey = '';
        notifsMap.forEach((key, value) {
          if (key != 'state' && key != 'notifTime') {
            if (value['note'].toString() ==
                '${widget.date}: ${widget.locationAddress}') {
              delete = true;
              mapKey = key.toString();
            }
          }
        });
        if (delete) {
          notifRef.child(mapKey).remove();
        }
      } catch (e1) {
        print('Error: $e1');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Input value must be a number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.locationName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.locationAddress,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.date,
              style: const TextStyle(fontSize: 16),
            ),
            Form(
                key: _formKey,
                child: LocationInput(
                  locationAddress: widget.locationAddress,
                  locationName: widget.locationName,
                  date: widget.date,
                  deleteNotif: () => submitExpense(expenseController.text,
                      selectedBudget, selectedCategory, context),
                )),
          ],
        ),
      ),
    );
  }
}

class LocationInput extends StatefulWidget {
  final String locationName;
  final String locationAddress;
  final String date;
  final VoidCallback deleteNotif;

  LocationInput(
      {required this.date,
      required this.locationName,
      required this.locationAddress,
      required this.deleteNotif});

  @override
  _LocationInputState createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  Future<List> getUserBudgets() async {
    DataSnapshot budgetsSnapshot = await userBudgetsReference.get();
    List<dynamic> budgets = ['Select a Budget'];

    if (budgetsSnapshot.exists) {
      Map<dynamic, dynamic> budgetMap = budgetsSnapshot.value as Map;
      budgets.addAll(budgetMap.keys);
    }
    print(budgets);

    return budgets;
  }

  Future<List> getBudgetCategories(String budget) async {
    DataSnapshot categoriesSnapshot =
        await userBudgetsReference.child('$budget/budgetMap').get();
    List<dynamic> categories = ['Select a Category'];

    if (categoriesSnapshot.exists) {
      Map<dynamic, dynamic> categoryMap = categoriesSnapshot.value as Map;
      categories.addAll(categoryMap.keys);
    }
    print(categories);

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: expenseController,
            decoration: const InputDecoration(labelText: 'Enter a number'),
            keyboardType: TextInputType.number,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: getUserBudgets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                return DropdownButton<String>(
                  value: selectedBudget,
                  items: snapshot.data!.map<DropdownMenuItem<String>>((budget) {
                    return DropdownMenuItem<String>(
                      value: budget,
                      child: Text(budget),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedBudget = value!;
                    });
                  },
                );
              }
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: getBudgetCategories(selectedBudget),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                return DropdownButton<String>(
                  value: selectedCategory,
                  items:
                      snapshot.data!.map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                );
              }
            },
          ),
        ),
        ElevatedButton(
            onPressed: () => widget.deleteNotif(), child: const Text('Submit'))
      ],
    );
  }
}
