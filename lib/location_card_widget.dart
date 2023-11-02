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

class LocationCard extends StatelessWidget {
  final String locationName;
  final String locationAddress;
  final String date;

  LocationCard(
      {required this.date,
      required this.locationName,
      required this.locationAddress});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              locationName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              locationAddress,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              date,
              style: const TextStyle(fontSize: 16),
            ),
            Form(
              key: _formKey,
              child: LocationInput(
                locationAddress: locationAddress,
                locationName: locationName,
                date: date,)
            ),
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

  LocationInput(
      {required this.date,
      required this.locationName,
      required this.locationAddress});

  @override
  _LocationInputState createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  String selectedBudget = 'Select a Budget';
  String selectedCategory = 'Select a Category';
  TextEditingController expenseController = TextEditingController();

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
            onPressed: () => submitExpense(expenseController.text,
                selectedBudget, selectedCategory, context),
            child: const Text('Submit'))
      ],
    );
  }
}
