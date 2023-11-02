import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_colors.dart';

class BudgetCreationPopup extends StatefulWidget {
  final void Function(Map<String, double>, String, List<Color>) onBudgetCreated;

  BudgetCreationPopup({required this.onBudgetCreated});

  @override
  _BudgetCreationPopupState createState() => _BudgetCreationPopupState();
}

class _BudgetCreationPopupState extends State<BudgetCreationPopup> {
  List<BudgetItem> budgetItems = [
    BudgetItem(categoryName: "", percentage: 0.0)
  ]; // Initialize with one item

  Map<String, double> budgetMap = {}; // Initialize the budgetMap

  TextEditingController budgetAmountController = TextEditingController();
  TextEditingController budgetNameController = TextEditingController();
  String budgetNameError = '';
  String budgetAmountError = '';

  String colorChoice = "Green";

  final Map<String, List<Color>> colorMap = {
    "Green": greenColorList,
    "Blue": blueColorList,
    "Orange": orangeColorList,
    "Purple": purpleColorList,
    "Black": blackColorList,
  };

  List<String> colorOptions = ["Green", "Blue", "Orange", "Purple", "Black"];

  @override
  void dispose() {
    budgetAmountController
        .dispose(); // Dispose of the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Budget"),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: budgetNameController,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: "Enter Budget Name",
                errorText: budgetNameError, // Display error message
              ),
            ),
            const Divider(),
            TextField(
              controller: budgetAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Enter Budget Amount",
                errorText: budgetAmountError, // Display error message
              ),
            ),
            Text("Color Scheme:"),
            DropdownButtonFormField<String>(
              value: colorChoice,
              items: colorOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                colorChoice = newValue!;
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: budgetItems.length,
                itemBuilder: (context, index) {
                  return BudgetItemInput(
                      item: budgetItems[index],
                      onDelete: () {
                        setState(() {
                          budgetItems.removeAt(index);
                        });
                      },
                      onUpdate: () {
                        setState(() {});
                      },
                      budgetAmount:
                          double.tryParse(budgetAmountController.text) ?? 0.0,
                      categoryError: getCategoryError(budgetItems[index]));
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add a new empty BudgetItem
                setState(() {
                  budgetItems
                      .add(BudgetItem(categoryName: "", percentage: 0.0));
                });
              },
              child: const Text("Add Budget Item"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (validateInputs()) {
                  double totalPercentage = 0;
                  for (var item in budgetItems) {
                    totalPercentage += item.percentage;
                  }

                  // Close the popup and send the created budget back
                  Navigator.of(context).pop();

                  // Get the budget amount from the text field
                  double budgetAmount =
                      double.tryParse(budgetAmountController.text) ?? 0.0;
                  print("Budget Amount: \$${budgetAmount.toStringAsFixed(2)}");

                  // Process the budgetItems list here
                  // You can access category names and percentages from budgetItems

                  // Update the budgetMap with the category and slider value
                  for (var item in budgetItems) {
                    budgetMap[item.categoryName] = double.parse(
                        (item.percentage / 100 * budgetAmount)
                            .toStringAsFixed(2));
                  }

                  //colorChoice;
                  print(budgetMap);
                  widget.onBudgetCreated(budgetMap, budgetNameController.text,
                      colorMap[colorChoice]!);
                }
              },
              child: const Text("Make Budget"),
            ),
          ],
        ),
      ),
    );
  }

  String getCategoryError(BudgetItem item) {
    if (item.categoryName.isEmpty) {
      return 'Category Name is required';
    }
    return ''; // No error
  }

  bool validateInputs() {
    bool isValid = true;
    budgetNameError = '';
    budgetAmountError = '';

    String categoryError = '';

    if (budgetNameController.text.isEmpty) {
      budgetNameError = 'Budget Name is required';
      isValid = false;
    }

    if (budgetAmountController.text.isEmpty) {
      budgetAmountError = 'Budget Amount is required';
      isValid = false;
    } else {
      double? budgetAmount = double.tryParse(budgetAmountController.text);
      if (budgetAmount == null || budgetAmount <= 0) {
        budgetAmountError = 'Invalid Budget Amount';
        isValid = false;
      }
    }

    if (budgetItems.any((item) => item.categoryName.isEmpty)) {
      categoryError =
          'Category Name is required'; // Check if any category name is empty
      isValid = false;
    }

    setState(() {}); // Update the UI with error messages
    return isValid;
  }
}

class BudgetItem {
  String categoryName = "";
  double percentage = 0.0;

  BudgetItem({required this.categoryName, required this.percentage});
}

class BudgetItemInput extends StatefulWidget {
  final BudgetItem item;
  final Function() onDelete;
  final Function() onUpdate;
  final double budgetAmount;
  final String categoryError;

  BudgetItemInput({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.budgetAmount,
    required this.categoryError,
  });

  @override
  _BudgetItemInputState createState() => _BudgetItemInputState();
}

class _BudgetItemInputState extends State<BudgetItemInput> {
  String category = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    widget.item.categoryName = value;
                    category = value;
                    widget
                        .onUpdate(); // Call onUpdate when the category name changes
                  });
                },
                decoration: const InputDecoration(labelText: "Category Name"),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Text(
                    "\$${(widget.item.percentage / 100 * widget.budgetAmount).toStringAsFixed(2)}", // Display the calculated percentage
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Slider(
                    value: widget.item.percentage,
                    onChanged: (value) {
                      setState(() {
                        widget.item.percentage = value;
                        widget.onUpdate();
                      });
                    },
                    min: 0,
                    max: 100,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        // Display the category error message
        Text(
          widget.categoryError,
          style: const TextStyle(color: Colors.red),
        ),
      ],
    );
  }
}
