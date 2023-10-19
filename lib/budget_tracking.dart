import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_creation.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/usage_table.dart';
import 'package:financefriend/budget_tracking_widgets/budget_category.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

Future<Map<String, double>> getBudgetMapFromFirebase() async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return {}; // Return an empty map or an appropriate default value
  }

  try {
    final budgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetMap/budgetData');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetReference.once();
    DataSnapshot snapshot = event.snapshot;

    // Check if the data exists
    if (snapshot.value != null) {
      // Use explicit type casting to ensure all values are of type double
      Map<String, dynamic> dynamicMap = snapshot.value as Map<String, dynamic>;
      Map<String, double> budgetMap = {};

      dynamicMap.forEach((key, value) {
        if (value is double) {
          budgetMap[key] = value;
        } else if (value is int) {
          budgetMap[key] = value.toDouble();
        } else if (value is String) {
          budgetMap[key] = double.tryParse(value) ?? 0.0;
        }
      });

      return budgetMap;
    } else {
      // Handle the case where the data does not exist
      return {}; // Return an empty map or an appropriate default value
    }
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error fetching budgetMap from Firebase: $error");
    return {}; // Return an empty map or an appropriate default value
  }
}

Future<String> getBudgetNameFromFirebase() async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return ""; // Return an empty map or an appropriate default value
  }

  try {
    final budgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetMap/budgetName');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetReference.once();
    DataSnapshot snapshot = event.snapshot;

    // Check if the data exists
    if (snapshot.value != null) {
      // Use explicit type casting to ensure all values are of type double
      return snapshot.value as String;
    } else {
      // Handle the case where the data does not exist
      return ""; // Return an empty map or an appropriate default value
    }
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error fetching budgetMap from Firebase: $error");
    return ""; // Return an empty map or an appropriate default value
  }
}

Future<bool> createBudgetInFirebase(
    String budgetName, Map<String, double> budgetMap) async {
  // final reference = FirebaseDatabase.instance.reference();
  // final currentUser = FirebaseAuth.instance.currentUser;
  print("Putting data in database");

  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final newBudgetReference =
        reference.child('users/${currentUser?.uid}/budgets/budgetMap');

    // Store the budgetMap under the unique key
    await newBudgetReference.child("budgetData").set(budgetMap);

    // Optionally, you can store the budgetName as well
    await newBudgetReference.child('budgetName').set(budgetName);
    await newBudgetReference.child("expenses").push();

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error creating budget in Firebase: $error");
    return false;
  }
}

Future<bool> updateBudgetInFirebase(
    Map<String, double> updatedBudgetMap) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgets/budgetMap');

    // Update the budgetMap with the new data
    await budgetReference.child("budgetData").update(updatedBudgetMap);

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error updating budget in Firebase: $error");
    return false;
  }
}

Future<bool> checkIfBudgetExists() async {
  // final reference = FirebaseDatabase.instance.reference();
  // final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final budgetReference = reference.child('users/${currentUser?.uid}');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetReference.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.hasChild("budgetMap")) {
      final budgetMapReference =
          reference.child('users/${currentUser?.uid}/budgets/budgetMap');
      DatabaseEvent event2 = await budgetMapReference.once();
      DataSnapshot snapshot2 = event2.snapshot;
      if (snapshot2.hasChild("budgetName") &&
          snapshot2.hasChild("budgetData")) {
        return true;
      }
    }
    return false;
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error creating budget in Firebase: $error");
    return false;
  }
}

Future<bool> updateBudgetNameInFirebase(String newBudgetName) async {
  if (currentUser == null) {
    return false;
  }

  try {
    final budgetNameReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetMap/budgetName');

    await budgetNameReference.set(newBudgetName);

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error updating budget name in Firebase: $error");
    return false;
  }
}

Future<bool> deleteBudgetFromFirebase() async {
  if (currentUser == null) {
    return false;
  }

  try {
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgets/budgetMap');

    // Delete the budgetData and budgetName nodes
    await budgetReference.child("budgetData").remove();
    await budgetReference.child('budgetName').remove();
    await budgetReference.child("expenses").remove();

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error deleting budget from Firebase: $error");
    return false;
  }
}

class BudgetTracking extends StatefulWidget {
  @override
  _BudgetTrackingState createState() => _BudgetTrackingState();
}

class _BudgetTrackingState extends State<BudgetTracking> {
  late TextEditingController controller;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController newBudgetNameController =
      TextEditingController(); // Step 1: Create the controller

  String actualCategory = "";
  bool values_added = false;

  String selectedCategory = "Select Category";
  bool isFormValid = false;
  bool budgetCreated = false;

  List<Expense> expenseList = <Expense>[];

  Map<String, double> budgetMap = {};
  double budgetAmount = 0;
  String budgetName = "";

  @override
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    setBudgetInit(); // Check if a budget already exists
  }

  Future<void> setBudgetInit() async {
    final budgetExists = await checkIfBudgetExists();
    if (budgetExists) {
      final existingBudgetMap = await getBudgetMapFromFirebase();
      final existingBudgetName = await getBudgetNameFromFirebase();

      print(existingBudgetMap);
      print(existingBudgetName);

      setState(() {
        budgetMap = existingBudgetMap;
        budgetName = existingBudgetName;
      });
    }
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
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Image.asset('images/FFLogo.png'),
          onPressed: () => {Navigator.pushNamed(context, '/home')},
        ),
        title: const Text('FinanceFriend Dashboard',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(children: <Widget>[
              Visibility(
                visible:
                    budgetMap.isEmpty, // Show the button if budgetMap is empty
                child: Column(children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        budgetMap = {
                          "Housing": 250,
                          "Utilities": 250,
                          "Food": 150,
                          "Transportation": 140,
                          "Entertainment": 120,
                          "Investments": 50,
                          "Debt Payments": 40
                        };
                        budgetName = "Default";
                        createBudgetInFirebase("Default", budgetMap);

                        // print("printing budget:");
                        // print((await getBudgetMapFromFirebase()).toString());
                        // You can also set other values here if needed.
                      });
                    },
                    child: const Text("Set Default Budget"),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return BudgetCreationPopup(onBudgetCreated:
                              (Map<String, double> budgetMap,
                                  String budgetName) {
                            // Step 1: Create the budget in Firebase
                            createBudgetInFirebase(budgetName, budgetMap)
                                .then((result) {
                              if (result == true) {
                                // Step 2: Update local state after Firebase operation is successful
                                setState(() {
                                  this.budgetMap = budgetMap;
                                  this.budgetName = budgetName;
                                  budgetCreated = true;
                                });
                              } else {
                                // Handle error or show an error message
                              }
                            });
                          });
                        },
                      );
                    },
                    child: const Text("Create New Budget"),
                  ),
                ]),
              ),
              Visibility(
                visible: budgetMap.isNotEmpty,
                child: Column(
                  children: <Widget>[
                    Visibility(
                      visible: budgetMap.isNotEmpty,
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: [
                                Text(
                                  "Budget: $budgetName",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    editBudgetName();
                                  },
                                ),
                              ],
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

                                      // Check if the category already exists in the budgetMap
                                      if (budgetMap
                                          .containsKey(actualCategory)) {
                                        // If it exists, update the existing value
                                        double currentValue =
                                            budgetMap[actualCategory] ?? 0.0;
                                        double newValue = double.parse(resp);
                                        budgetMap[actualCategory] =
                                            currentValue + newValue;
                                      } else {
                                        // If it doesn't exist, add a new entry
                                        budgetMap[actualCategory] =
                                            double.parse(resp);
                                      }
                                      values_added = true;
                                    });
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
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            ExpenseTracking(
                              budgetMap: budgetMap,
                              dropdownItems: dropdownItems,
                              expensesList: expenseList,
                              onExpensesListChanged: (updatedExpensesList) {
                                setState(() {
                                  expenseList = updatedExpensesList;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    ElevatedButton(
                      // Add a button to delete the budget
                      child: const Text(
                        "Delete Budget",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        deleteBudget();
                      },
                    ),
                    const SizedBox(
                      height: 40,
                    )
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void deleteBudget() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Budget"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Are you sure you want to delete the budget? This action cannot be undone."),
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
              onPressed: () {
                // Delete the budget from the database and reset the local state
                deleteBudgetFromFirebase().then((success) {
                  if (success) {
                    setState(() {
                      budgetMap = {};
                      budgetName = "";
                    });
                  }
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void editBudgetName() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Budget Name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller:
                    newBudgetNameController, // Step 3: Use the controller for user input
                decoration: const InputDecoration(labelText: "New Budget Name"),
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
              onPressed: () {
                String newBudgetName = newBudgetNameController.text;
                // Step 4: Call updateBudgetNameInFirebase with the new budget name
                updateBudgetNameInFirebase(newBudgetName).then((success) {
                  if (success) {
                    // Update the local budgetName if the operation is successful
                    setState(() {
                      budgetName = newBudgetName;
                    });
                  }
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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
                            style: const TextStyle(),
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
            child: BudgetCategoryTable(
              budgetMap: budgetMap,
              onBudgetUpdate: (updatedBudgetMap) async {
                bool updateResult =
                    await updateBudgetInFirebase(updatedBudgetMap);

                if (updateResult) {
                  // If the update was successful, update the local state
                  setState(() {
                    budgetMap = updatedBudgetMap;
                  });
                } else {
                  // Handle the case where the update in Firebase failed
                  // You can show an error message or take appropriate action here
                }
              },
            ));
      },
    );
  }

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
    updateBudgetInFirebase(budgetMap);
  }

  double getTotalBudget(Map<String, double> budgetMap) {
    double total = budgetMap.values.fold(0, (previousValue, currentValue) {
      return previousValue + currentValue;
    });

    return double.parse(total.toStringAsFixed(2));
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
        chartValueStyle: const TextStyle(fontSize: 20),
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
