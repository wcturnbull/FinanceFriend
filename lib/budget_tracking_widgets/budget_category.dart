import 'package:financefriend/budget_tracking.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_creation.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/usage_table.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

Future<bool> removeBudgetCategory(String categoryName) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final newBudgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetMap/budgetData');

    print("trying to remove: " + categoryName);

    await newBudgetReference.child(categoryName).remove();

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error creating budget in Firebase: $error");
    return false;
  }
}

class BudgetCategoryTable extends StatefulWidget {
  final Map<String, double> budgetMap;
  final Function(Map<String, double>) onBudgetUpdate;

  BudgetCategoryTable({required this.budgetMap, required this.onBudgetUpdate});

  @override
  _BudgetCategoryTableState createState() => _BudgetCategoryTableState();
}

class _BudgetCategoryTableState extends State<BudgetCategoryTable> {
  TextEditingController editController = TextEditingController();
  String editingCategory = "";

  @override
  void dispose() {
    editController.dispose();
    super.dispose();
  }

  void editCategoryValue(String category) {
    setState(() {
      editingCategory = category;
      editController.text = widget.budgetMap[category]!.toStringAsFixed(2);
    });

    String editedCategory = category;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: category, // Set initial category name
                onChanged: (value) {
                  setState(() {
                    editedCategory = value; // Update edited category name
                  });
                },
                decoration: const InputDecoration(labelText: "Category Name"),
              ),
              TextFormField(
                controller: editController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "New Value"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a value.";
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
                onPressed: () async {
                  widget.budgetMap.remove(category);
                  widget.onBudgetUpdate(widget.budgetMap);
                  bool success = await removeBudgetCategory(category);
                  if (success) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  "Delete Category",
                  style: TextStyle(color: Colors.red),
                )),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.isNotEmpty) {
                  double newValue = double.tryParse(editController.text) ?? 0;
                  print("category: " + category);
                  widget.budgetMap.remove(category);
                  await removeBudgetCategory(category);
                  // print(widget.budgetMap);
                  // await updateBudgetInFirebase(widget.budgetMap);
                  // print(await getBudgetMapFromFirebase());
                  widget.budgetMap[editedCategory] = newValue;
                  widget.onBudgetUpdate(widget.budgetMap);
                  final success =
                      await updateBudgetInFirebase(widget.budgetMap);
                  if (success) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  void removeCategory(String category) {
    widget.budgetMap.remove(category);
    widget.onBudgetUpdate(widget.budgetMap);
    updateBudgetInFirebase(widget.budgetMap); // Update the database
  }

  @override
  Widget build(BuildContext context) {
    double getTotalBudget(Map<String, double> budgetMap) {
      double total = budgetMap.values.fold(0, (previousValue, currentValue) {
        return previousValue + currentValue;
      });
      return double.parse(total.toStringAsFixed(2));
    }

    final totalBudget = getTotalBudget(widget.budgetMap);
    final formattedTotalBudget = NumberFormat.currency(
      symbol: '\$', // Use "$" as the currency symbol
      decimalDigits: 2, // Display two decimal places
    ).format(totalBudget);

    final budgetItems = widget.budgetMap.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$$amount',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    editCategoryValue(category);
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    }).toList();

    return AlertDialog(
      title: const Text(
        "Current Budget",
        style: TextStyle(
          fontSize: 22,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: budgetItems,
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
      actions: [
        Center(
          child: Text(
            "Total: $formattedTotalBudget",
            style: const TextStyle(fontSize: 20, fontFamily: "Trebuchet"),
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text("Close", style: TextStyle()),
        ),
      ],
    );
  }
}
