import 'package:financefriend/budget_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_creation.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/usage_table.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';

class BudgetCategoryTable extends StatefulWidget {
  final Function(Map<String, double>) onBudgetUpdate;
  Budget budget;

  BudgetCategoryTable({required this.budget, required this.onBudgetUpdate});

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
      editController.text =
          widget.budget.budgetMap[category]!.toStringAsFixed(2);
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
                  widget.budget.budgetMap.remove(category);
                  widget.onBudgetUpdate(widget.budget.budgetMap);
                  bool success = await removeBudgetCategory(
                      widget.budget.budgetName, category);
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
                  widget.budget.budgetMap.remove(category);
                  await removeBudgetCategory(
                      widget.budget.budgetName, category);
                  // print(widget.budget.budgetMap);
                  // await updateBudgetInFirebase(widget.budget.budgetMap);
                  // print(await getBudgetMapFromFirebase());
                  widget.budget.budgetMap[editedCategory] = newValue;
                  widget.onBudgetUpdate(widget.budget.budgetMap);
                  final success = await updateBudgetInFirebase(
                      widget.budget.budgetName, widget.budget.budgetMap);
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
    widget.budget.budgetMap.remove(category);
    widget.onBudgetUpdate(widget.budget.budgetMap);
    updateBudgetInFirebase(widget.budget.budgetName,
        widget.budget.budgetMap); // Update the database
  }

  @override
  Widget build(BuildContext context) {
    double getTotalBudget(Map<String, double> budgetMap) {
      double total = budgetMap.values.fold(0, (previousValue, currentValue) {
        return previousValue + currentValue;
      });
      return double.parse(total.toStringAsFixed(2));
    }

    final totalBudget = getTotalBudget(widget.budget.budgetMap);
    final formattedTotalBudget = NumberFormat.currency(
      symbol: '\$', // Use "$" as the currency symbol
      decimalDigits: 2, // Display two decimal places
    ).format(totalBudget);

    final budgetItems = widget.budget.budgetMap.entries.map((entry) {
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
