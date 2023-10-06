import 'dart:io';

import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:data_table_2/data_table_2.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

Map<String, double> getBudgetMapFromDB() {
  Map<String, double> budgetData = {};
  reference
      .child('users/${currentUser?.uid}/budgetMap')
      .onValue
      .listen((event) {
    final dynamic snapshotValue = event.snapshot.value;
    if (snapshotValue != null && snapshotValue is String) {
      budgetData = Map<String, double>.from(
        jsonDecode(snapshotValue),
      );

      print("Budget Data from database:");
      print(budgetData);
      print("data printed");
      // Now you have the JSON data from the database as a Map<String, dynamic>
    } else {
      print("No budget data found in the database.");
    }
  });
  return budgetData;
}

void putBudgetMapInDB() {}

class BudgetTracking extends StatefulWidget {
  @override
  _BudgetTrackingState createState() => _BudgetTrackingState();
}

class _BudgetTrackingState extends State<BudgetTracking> {
  late TextEditingController controller;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String actualCategory = "";
  bool values_added = false;

  String selectedCategory = "Select Category";
  bool isFormValid = false;
  bool budgetCreated = false;

  // Map<String, double> budgetMap = {
  //   "Housing": 250,
  //   "Utilities": 250,
  //   "Food": 150,
  //   "Transportation": 140,
  //   "Entertainment": 120,
  //   "Investments": 50,
  //   "Debt Payments": 40
  // };
  Map<String, double> budgetMap = {};

  List<Expense> expenseList = <Expense>[];

  // Map<String, double> budgetMap = {};
  double budgetAmount = 0;
  String budgetName = "Sample Budget";

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  final Color color =
      Color(int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000);

  final colorList = <Color>[
    Color(int.parse("#124309".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#15510a".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#1c6c0e".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#4f9f41".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#7bb770".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#a7cfa0".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#d3e7cf".substring(1, 7), radix: 16) + 0xFF0000000),
  ];

  List<String> dropdownItems = [
    "Select Category",
    "Housing",
    "Utilities",
    "Food",
    "Transportation",
    "Entertainment",
    "Investments",
    "Debt Payments",
    "Custom",
  ];

  var options = ["Option 1", "Option 2", "Option 3"];

  TextEditingController customCategoryController = TextEditingController();
  bool isOtherSelected = false;
  bool afterBudgetAmt = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: const FFAppBar(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(children: <Widget>[
              Visibility(
                visible:
                    budgetMap.isEmpty, // Show the button if budgetMap is empty
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return BudgetCreationPopup(
                          onBudgetCreated: (Map<String, double> budgetMap,
                              String budgetName) {
                            setState(() {
                              this.budgetMap = budgetMap;
                              this.budgetName = budgetName;
                              budgetCreated = true;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: Text("Create New Budget"),
                ),
              ),
              Visibility(
                visible: budgetMap.isNotEmpty,
                child: Column(
                  children: <Widget>[
                    Transform.scale(
                      scale: 1.25,
                      child: Visibility(
                        visible: budgetMap.isNotEmpty,
                        child: Column(
                          children: <Widget>[
                            Text(
                              "Budget: $budgetName",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 35),
                            Builder(
                              builder: (BuildContext context) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    final resp = await openAddToBudget();
                                    if (resp == null || resp.isEmpty) return;
                                    print(resp);
                                    setState(() {
                                      if (!dropdownItems
                                          .contains(actualCategory)) {
                                        dropdownItems.insert(
                                            dropdownItems.length - 1,
                                            actualCategory);
                                      }
                                      budgetMap.addAll(
                                          {actualCategory: double.parse(resp)});
                                      values_added = true;
                                    });
                                    print(budgetMap);
                                  },
                                  child: const Text("Add Spending Category",
                                      style: TextStyle()),
                                );
                              },
                            ),
                            Visibility(
                              visible: budgetMap.isNotEmpty,
                              child: Column(
                                children: <Widget>[
                                  const SizedBox(height: 35),
                                  BudgetPieChart(
                                    budgetMap: budgetMap,
                                    valuesAdded: budgetMap.isNotEmpty,
                                    colorList: colorList,
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 35),
                            Builder(
                              builder: (BuildContext context) {
                                return ElevatedButton(
                                  onPressed: openBudgetTable,
                                  child: const Text("View Current Budget",
                                      style: TextStyle()),
                                );
                              },
                            ),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Center the columns horizontally
                      children: [
                        Column(
                          children: [
                            BudgetUsageTable(
                              budgetMap: budgetMap,
                              expensesList: expenseList,
                            )
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            MiddleSection(
                              budgetMap: budgetMap,
                              dropdownItems: dropdownItems,
                              expensesList: expenseList,
                              onExpensesListChanged: (updatedExpensesList) {
                                setState(() {
                                  expenseList =
                                      updatedExpensesList; // Update the expensesList
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                      ],
                    )

                    // Right side text
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<String?> openAddToBudget() => showDialog<String>(
        context: scaffoldKey.currentContext!,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Enter Expense:", style: TextStyle()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: dropdownItems.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                          isFormValid =
                              newValue != "Select Category" && !isOtherSelected;
                          // Check if "Custom" is selected
                          isOtherSelected = newValue == "Custom";
                        });
                      },
                    ),
                    // Show a text field if "Other" is selected
                    if (isOtherSelected)
                      TextField(
                        controller: customCategoryController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a custom category',
                        ),
                      ),
                    const SizedBox(height: 10), // Add some spacing
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                          hintText: 'Enter your expense amount (i.e. \$25)',
                          hintStyle: TextStyle()),
                      controller: controller,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      submit();
                      setState(() {
                        values_added = true;
                      });
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text("Submit", style: TextStyle()),
                  ),
                ],
              );
            },
          );
        },
      );

  Future<void> openBudgetTable() async {
    await showDialog(
      context: scaffoldKey.currentContext!,
      builder: (context) {
        return Visibility(
            visible: budgetMap.isNotEmpty,
            child: BudgetTable(
              budgetMap: budgetMap,
              onBudgetUpdate: (updatedBudgetMap) {
                setState(() {
                  budgetMap = updatedBudgetMap;
                });
              },
            ));
      },
    );
  }

  double curr_val = 0;

  void submit() {
    actualCategory = selectedCategory;
    if (isOtherSelected) {
      // Use the custom category name if "Other" is selected
      actualCategory = customCategoryController.text;
    }
    if (actualCategory != "Select Category") {
      setState(() {
        if (budgetMap.containsKey(actualCategory)) {
          budgetMap[actualCategory] =
              (budgetMap[actualCategory]! + double.parse(controller.text))!;
        } else {
          budgetMap[actualCategory.toString()] = double.parse(controller.text);
          if (!dropdownItems.contains(actualCategory)) {
            dropdownItems.insert(dropdownItems.length - 1, actualCategory);
          }
        }
      });
      selectedCategory = "Select Category";
    }
    controller.clear();
    customCategoryController.clear();
    isOtherSelected = false;
  }

  double getTotalBudget(Map<String, double> budgetMap) {
    double total = budgetMap.values.fold(0, (previousValue, currentValue) {
      return previousValue + currentValue;
    });

    return double.parse(total.toStringAsFixed(2));
  }
}

class BudgetTable extends StatefulWidget {
  final Map<String, double> budgetMap;
  final Function(Map<String, double>) onBudgetUpdate;

  BudgetTable({required this.budgetMap, required this.onBudgetUpdate});

  @override
  _BudgetTableState createState() => _BudgetTableState();
}

class _BudgetTableState extends State<BudgetTable> {
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
          title: Text("Edit Category"),
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
                decoration: InputDecoration(labelText: "Category Name"),
              ),
              TextFormField(
                controller: editController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "New Value"),
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
              child: Text("Cancel"),
            ),
            ElevatedButton(
                onPressed: () {
                  widget.budgetMap.remove(category);
                  widget.onBudgetUpdate(widget.budgetMap);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Delete Category",
                  style: TextStyle(color: Colors.red),
                )),
            ElevatedButton(
              onPressed: () {
                if (editController.text.isNotEmpty) {
                  double newValue = double.tryParse(editController.text) ?? 0;
                  widget.budgetMap.remove(category); // Remove the old category
                  widget.budgetMap[editedCategory] =
                      newValue; // Add the new category
                  widget.onBudgetUpdate(widget.budgetMap);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void removeCategory(String category) {
    widget.budgetMap.remove(category);
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;

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
                  style: TextStyle(fontSize: 16),
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
          SizedBox(
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

class BudgetPieChart extends StatelessWidget {
  final Map<String, double> budgetMap;
  final bool valuesAdded;
  final List<Color> colorList;
  final Color color;

  BudgetPieChart({
    required this.budgetMap,
    required this.valuesAdded,
    required this.colorList,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final totalBudget = getTotalBudget(budgetMap);
    final formattedTotalBudget = NumberFormat.currency(
      symbol: '\$', // Use "$" as the currency symbol
      decimalDigits: 0, // No decimal places
    ).format(totalBudget);

    final filteredLegendItems = budgetMap.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    return PieChart(
      key: UniqueKey(),
      dataMap: budgetMap,
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 80,
      chartRadius: 300,
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 35,
      centerText: formattedTotalBudget,
      centerTextStyle: TextStyle(
        color: Color(
            int.parse("#124309".substring(1, 7), radix: 16) + 0xFF0000000),
        fontSize: 40,
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValues: valuesAdded,
        showChartValuesInPercentage: true,
        showChartValueBackground: false,
        decimalPlaces: 0,
        chartValueStyle: TextStyle(fontSize: 20),
      ),
      // legendLabels: ,
      //legendLabels: budgetMap.entries.where((element) => ),
      legendOptions: valuesAdded
          ? const LegendOptions(
              showLegends: true,
              legendPosition: LegendPosition.right,
              legendTextStyle: TextStyle(
                fontSize: 14,
              ),
              legendShape: BoxShape.circle)
          : const LegendOptions(
              showLegends: false,
            ),
      baseChartColor: Colors.white,
      colorList: colorList,
    );
  }

  double getTotalBudget(Map<String, double> budgetMap) {
    double total = budgetMap.values.fold(0, (previousValue, currentValue) {
      return previousValue + currentValue;
    });

    return double.parse(total.toStringAsFixed(2));
  }
}

class BudgetDataTable extends StatefulWidget {
  final List<Expense> expenseList;
  final Function(Expense) onEditExpense;
  final Function(Expense) onDeleteExpense;

  BudgetDataTable({
    required this.expenseList,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  @override
  _BudgetDataTableState createState() => _BudgetDataTableState();
}

class _BudgetDataTableState extends State<BudgetDataTable> {
  List<DataColumn> columns = [
    DataColumn(label: Text('Date')),
    DataColumn(
      label: Text('Item'),
    ),
    DataColumn(
      label: Text('Price'),
      numeric: true,
    ),
    DataColumn(
      label: Text('Category'),
    ),
    DataColumn(
      label: Text('Actions'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: columns,
      sortColumnIndex: null, // Disable sorting
      rows: widget.expenseList.isEmpty
          ? [
              DataRow(cells: [DataCell(Text('No expenses'))])
            ]
          : generateExpenseRows(widget.expenseList),
    );
  }

  List<DataRow> generateExpenseRows(List<Expense> expenses) {
    List<DataRow> rows = [];

    for (int i = 0; i < expenses.length; i++) {
      Expense expense = expenses[i];
      rows.add(DataRow(
        cells: [
          DataCell(Text(expense.date.toString())),
          DataCell(Text(expense.item)),
          DataCell(Text('\$${expense.price.toStringAsFixed(2)}')),
          DataCell(Text(expense.category)),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    widget.onEditExpense(expense);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    widget.onDeleteExpense(expense);
                  },
                ),
              ],
            ),
          ),
        ],
      ));
    }

    return rows;
  }
}

class MiddleSection extends StatefulWidget {
  final Map<String, double> budgetMap;
  final List<String> dropdownItems;
  final List<Expense> expensesList;
  final Function(List<Expense>) onExpensesListChanged; // Add this callback

  MiddleSection({
    required this.budgetMap,
    required this.dropdownItems,
    required this.expensesList,
    required this.onExpensesListChanged, // Initialize the callback
  });

  @override
  _MiddleSectionState createState() => _MiddleSectionState();
}

class _MiddleSectionState extends State<MiddleSection> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedCategory = "Select Category";

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 20,
      color: const Color.fromRGBO(102, 203, 19, 1),
      margin: EdgeInsets.all(30),
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Text(
            "Expenses List",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  _openAddExpenseDialog(context);
                },
                child: Text("Enter New Expense"),
              ),
              SizedBox(
                width: 10,
              )
            ],
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: EdgeInsets.all(30),
            child: Visibility(
              visible: widget.expensesList.isNotEmpty,
              child: SizedBox(
                width: 600,
                height: 250,
                child: SingleChildScrollView(
                  child: BudgetDataTable(
                    expenseList: widget.expensesList,
                    onEditExpense: _onEditExpense, // Pass the edit function
                    onDeleteExpense:
                        _onDeleteExpense, // Pass the delete function
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddExpenseDialog(BuildContext context) async {
    selectedCategory = "Select Category";
    itemController.clear();
    priceController.clear();

    // Create a filtered list of dropdown items without "Custom"
    List<String> catNames = widget.budgetMap.keys.toList();
    catNames.insert(0, "Select Category");

    final filteredDropdownItems =
        catNames.where((item) => item != "Custom").toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: itemController,
                decoration: InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: filteredDropdownItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _submitExpense();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _submitExpense() {
    final String item = itemController.text;
    final String price = priceController.text;

    if (item.isNotEmpty &&
        price.isNotEmpty &&
        selectedCategory != "Select Category") {
      double priceValue = double.tryParse(price) ?? 0.0;

      // Create a new Expense object
      Expense newExpense = Expense(
        item: item,
        price: priceValue,
        category: selectedCategory,
        date: DateFormat('MM/dd/yyyy').format(DateTime.now()),
      );

      // Add the newExpense to the expensesList
      widget.expensesList.add(newExpense);

      // Print the updated expensesList
      print("Expenses List:");
      for (Expense expense in widget.expensesList) {
        print(
            "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
      }

      // Clear text fields and selectedCategory
      itemController.clear();
      priceController.clear();
      selectedCategory = "Select Category";

      widget.onExpensesListChanged(widget.expensesList);

      setState(() {});
    }
  }

  // Function to handle editing an expense
  void _onEditExpense(Expense expenseToEdit) async {
    // Create controllers for editing
    final TextEditingController editedItemController =
        TextEditingController(text: expenseToEdit.item);
    final TextEditingController editedPriceController =
        TextEditingController(text: expenseToEdit.price.toString());
    String editedSelectedCategory = expenseToEdit.category;
    List<String> catNames = widget.budgetMap.keys.toList();
    catNames.insert(0, "Select Category");

    final filteredDropdownItems =
        catNames.where((item) => item != "Custom").toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editedItemController,
                decoration: InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: editedPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              DropdownButtonFormField<String>(
                value: editedSelectedCategory,
                items: filteredDropdownItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    editedSelectedCategory = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate and save the edited values
                final String editedItem = editedItemController.text;
                final String editedPrice = editedPriceController.text;

                if (editedItem.isNotEmpty &&
                    editedPrice.isNotEmpty &&
                    editedSelectedCategory != "Select Category") {
                  double editedPriceValue = double.tryParse(editedPrice) ?? 0.0;

                  // Update the values in the expensesList
                  final int indexOfEditedExpense =
                      widget.expensesList.indexOf(expenseToEdit);
                  if (indexOfEditedExpense != -1) {
                    widget.expensesList[indexOfEditedExpense] = Expense(
                      item: editedItem,
                      price: editedPriceValue,
                      category: editedSelectedCategory,
                      date: widget.expensesList[indexOfEditedExpense].date,
                    );
                  }

                  // Print the updated expensesList
                  print("Expenses List after editing:");
                  for (Expense expense in widget.expensesList) {
                    print(
                        "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
                  }

                  // Clear text fields and selectedCategory
                  editedItemController.clear();
                  editedPriceController.clear();
                  editedSelectedCategory = "Select Category";

                  setState(() {});
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );

    widget.onExpensesListChanged(widget.expensesList);
  }

  // Function to handle deleting an expense
  void _onDeleteExpense(Expense expenseToDelete) {
    // Remove the expense from the expensesList
    widget.expensesList.remove(expenseToDelete);

    // Print the updated expensesList
    print("Expenses List after deleting:");
    for (Expense expense in widget.expensesList) {
      print(
          "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
    }
    widget.onExpensesListChanged(widget.expensesList);

    setState(() {});
  }
}

class Expense {
  String item;
  double price;
  String category;
  String date; // Add a DateTime property for the date

  Expense({
    required this.item,
    required this.price,
    required this.category,
    required this.date, // Initialize the date property
  });
}

class BudgetUsageTable extends StatefulWidget {
  final Map<String, double> budgetMap;
  final List<Expense> expensesList;

  BudgetUsageTable({
    required this.budgetMap,
    required this.expensesList,
  });

  @override
  _BudgetUsageTableState createState() => _BudgetUsageTableState();
}

enum DisplayMode {
  Table,
  PieCharts,
  DonutChart,
}

class _BudgetUsageTableState extends State<BudgetUsageTable> {
  DisplayMode displayMode = DisplayMode.Table; // Initialize the display mode

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 20,
      color: const Color.fromRGBO(102, 203, 19, 1),
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Text(
            "Budget Usage",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          // Add buttons to switch between display modes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 5,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.Table;
                  });
                },
                child: Text("Table"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.PieCharts;
                  });
                },
                child: Text("Pie Charts"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.DonutChart;
                  });
                },
                child: Text("Ring Chart"), // Add Histogram button
              ),
              SizedBox(
                width: 5,
              ),
            ],
          ),
          SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: EdgeInsets.all(30),
            child: displayMode == DisplayMode.Table
                ? buildTable()
                : displayMode == DisplayMode.PieCharts
                    ? buildPieCharts()
                    : buildDonutCharts(), // Render content based on the selected display mode
          )
        ],
      ),
    );
  }

  Widget buildTable() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();

    return DataTable(
      columns: [
        DataColumn(label: Text("Category")),
        DataColumn(label: Text("Percentage")),
        DataColumn(label: Text("Dollar Amount")),
      ],
      rows: categoryUsageMap.entries.map((entry) {
        return DataRow(cells: [
          DataCell(Text(entry.key)),
          DataCell(Text("${entry.value.toStringAsFixed(2)}%")),
          DataCell(Text(
              "\$${widget.expensesList.where((expense) => expense.category == entry.key).fold(0, (prev, expense) => prev + expense.price.toInt()).toStringAsFixed(2)}"))
        ]);
      }).toList(),
    );
  }

  Widget buildPieCharts() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();
    final double totalBudget =
        widget.budgetMap.values.fold(0, (prev, amount) => prev + amount);
    final double totalExpenses =
        widget.expensesList.fold(0, (prev, expense) => prev + expense.price);

    final List<Widget> pieCharts = [];

    // Create a chart for overall expenses vs. overall budget
    final Map<String, double> overallDataMap = {
      "Spent": totalExpenses,
      "Available": totalBudget - totalExpenses,
    };
    pieCharts.add(
      Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Text(
            "Overall Budget",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChart(
            dataMap: overallDataMap,
            animationDuration: Duration(milliseconds: 800),
            chartLegendSpacing: 80,
            chartRadius: 100,
            initialAngleInDegree: 0,
            ringStrokeWidth: 20,
            centerTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            colorList: [
              Color(
                  int.parse("#871224".substring(1, 7), radix: 16) + 0xFF000000),
              const Color.fromRGBO(102, 203, 19, 1),
            ],
            // centerText:
            //     "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
            chartValuesOptions: ChartValuesOptions(
              showChartValues: false,
              showChartValuesInPercentage: true,
              showChartValuesOutside: true,
              showChartValueBackground: true,
              decimalPlaces: 0,
              chartValueStyle: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    categoryUsageMap.forEach((category, usage) {
      if (usage > 0) {
        final Map<String, double> dataMap = {
          "Spent": usage,
          "Available": 100 - usage,
        };
        pieCharts.add(
          Column(
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              PieChart(
                dataMap: dataMap,
                animationDuration: Duration(milliseconds: 800),
                chartLegendSpacing: 80,
                chartRadius: 100,
                initialAngleInDegree: 0,
                centerTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                colorList: [
                  Color(int.parse("#871224".substring(1, 7), radix: 16) +
                      0xFF000000),
                  const Color.fromRGBO(102, 203, 19, 1),
                ],
                // centerText:
                //     "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
                chartValuesOptions: ChartValuesOptions(
                  showChartValues: false,
                  showChartValuesInPercentage: true,
                  showChartValuesOutside: true,
                  showChartValueBackground: true,
                  decimalPlaces: 0,
                  chartValueStyle: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }
    });

    if (pieCharts.isEmpty) {
      return Text("No data to display");
    }

    return Column(
      children: pieCharts,
    );
  }

  Widget buildDonutCharts() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();
    final double totalBudget =
        widget.budgetMap.values.fold(0, (prev, amount) => prev + amount);
    final double totalExpenses =
        widget.expensesList.fold(0, (prev, expense) => prev + expense.price);

    final List<Widget> donutCharts = [];

    // Create a chart for overall expenses vs. overall budget
    final Map<String, double> overallDataMap = {
      "Spent": totalExpenses,
      "Available": totalBudget - totalExpenses,
    };

    donutCharts.add(Container(
      margin: EdgeInsets.all(10), // 20px margin around the donut chart
      child: Column(
        children: [
          Text(
            "Overall Budget",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          PieChart(
            dataMap: overallDataMap,
            animationDuration: Duration(milliseconds: 800),
            chartLegendSpacing: 80,
            chartRadius: 80,
            initialAngleInDegree: 0,
            chartType: ChartType.ring,
            ringStrokeWidth: 20,
            colorList: [
              Color(
                  int.parse("#871224".substring(1, 7), radix: 16) + 0xFF000000),
              const Color.fromRGBO(102, 203, 19, 1),
            ],
            centerText:
                "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
            chartValuesOptions: ChartValuesOptions(
              showChartValues: false,
              showChartValuesInPercentage: true,
              showChartValueBackground: false,
              decimalPlaces: 0,
              chartValueStyle: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    ));

    categoryUsageMap.forEach((category, usage) {
      if (usage > 0) {
        final Map<String, double> dataMap = {
          "Spent": usage,
          "Available": 100 - usage,
        };
        donutCharts.add(Container(
          margin: EdgeInsets.all(10), // 20px margin around the donut chart
          child: Column(
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              PieChart(
                dataMap: dataMap,
                animationDuration: Duration(milliseconds: 800),
                chartLegendSpacing: 80,
                chartRadius: 80,
                initialAngleInDegree: 0,
                chartType: ChartType.ring,
                ringStrokeWidth: 20,
                colorList: [
                  Color(int.parse("#871224".substring(1, 7), radix: 16) +
                      0xFF000000),
                  const Color.fromRGBO(102, 203, 19, 1),
                ],
                centerText: "${usage.toStringAsFixed(2)}%",
                chartValuesOptions: ChartValuesOptions(
                  showChartValues: false,
                  showChartValuesInPercentage: true,
                  showChartValueBackground: false,
                  decimalPlaces: 0,
                  chartValueStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ));
      }
    });

    if (donutCharts.isEmpty) {
      return Text("No data to display");
    }

    return Column(
      children: donutCharts,
    );
  }

  Map<String, double> calculateCategoryUsage() {
    final Map<String, double> categoryUsageMap = {};

    // Calculate the total budget amount
    double totalBudget =
        widget.budgetMap.values.fold(0, (prev, amount) => prev + amount);

    // Calculate the total expenses amount
    double totalExpenses =
        widget.expensesList.fold(0, (prev, expense) => prev + expense.price);

    // Calculate the percentage of each category used
    widget.budgetMap.forEach((category, budgetAmount) {
      double expensesAmount = widget.expensesList
          .where((expense) => expense.category == category)
          .fold(0, (prev, expense) => prev + expense.price);
      double categoryPercentage = (expensesAmount / budgetAmount) * 100;
      categoryUsageMap[category] = categoryPercentage;
    });

    return categoryUsageMap;
  }
}

class BudgetCreationPopup extends StatefulWidget {
  final void Function(Map<String, double>, String) onBudgetCreated;

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
  @override
  void dispose() {
    budgetAmountController
        .dispose(); // Dispose of the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Create Budget"),
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
            Divider(),
            TextField(
              controller: budgetAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Enter Budget Amount",
                errorText: budgetAmountError, // Display error message
              ),
            ),
            Divider(),
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
              child: Text("Add Budget Item"),
            ),
            SizedBox(height: 10),
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

                  print(budgetMap);
                  widget.onBudgetCreated(budgetMap, budgetNameController.text);
                }
              },
              child: Text("Make Budget"),
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
                decoration: InputDecoration(labelText: "Category Name"),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Text(
                    "\$${(widget.item.percentage / 100 * widget.budgetAmount).toStringAsFixed(2)}", // Display the calculated percentage
                    style: TextStyle(
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
              icon: Icon(Icons.delete),
            ),
          ],
        ),
        // Display the category error message
        Text(
          widget.categoryError,
          style: TextStyle(color: Colors.red),
        ),
      ],
    );
  }
}
