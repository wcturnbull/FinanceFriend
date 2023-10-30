import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:financefriend/budget_tracking_widgets/wishlist.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_tracking_widgets/budget_creation.dart';
import 'budget_tracking_widgets/expense_tracking.dart';
import 'budget_tracking_widgets/usage_table.dart';
import 'budget_tracking_widgets/budget_category.dart';
import 'budget_tracking_widgets/budget_db_utils.dart';
import 'budget_tracking_widgets/budget_colors.dart';

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

  List<String> budgetList = [];

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    getBudgetListFromFirebase(); // Fetch the list of budget names
  }

  Future<void> getBudgetListFromFirebase() async {
    if (currentUser == null) {
      return;
    }

    try {
      final budgetsRef = reference.child('users/${currentUser?.uid}/budgets');

      DatabaseEvent event = await budgetsRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<String, dynamic> budgetData =
            snapshot.value as Map<String, dynamic>;

        // Extract the list of budget keys
        List<String> budgetKeys = budgetData.keys.toList();

        setState(() {
          budgetList = budgetKeys;
        });
      }
    } catch (error) {
      print("Error fetching budget list from Firebase: $error");
    }
  }

  // Function to open a specific budget based on the selected budget name
  void openBudget(String selectedBudgetName) {
    setState(() {
      budgetName = selectedBudgetName;
      budgetMap = {}; // Clear the current budget map
      budgetCreated = false; // Reset budgetCreated to indicate loading
    });

    // Fetch the selected budget data and update your UI
    getBudgetFromFirebaseByName(selectedBudgetName).then((selectedBudget) {
      if (selectedBudget != null) {
        print(selectedBudget.expenses);
        setState(() {
          budgetMap = selectedBudget.budgetMap;
          expenseList = selectedBudget.expenses;
          budgetName = selectedBudget.budgetName;
          budgetCreated = true; // Set budgetCreated to true when data is loaded
          // Load other budget-related data as needed
        });
      } else {
        // Handle the case where the budget data could not be retrieved
        print("Error loading budget data.");
        // You can show an error message to the user if needed.
      }
    }).catchError((error) {
      print("Error fetching budget data: $error");
      // Handle the error. You might want to show an error message to the user.
    });
  }

  // Build the list of budget buttons
  Widget buildBudgetButtons() {
    if (budgetList.isEmpty) {
      return const Text("");
    }

    print("Printing budgetNames");
    print(budgetList);

    return Container(
      width: 300,
      child: Card(
        margin: const EdgeInsets.all(16),
        color: Colors.green,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Existing Budgets:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    width: 200, // Set a fixed width for the divider
                    child: const Divider(
                      color: Colors.white, // Change the color as needed
                      thickness: 1.0, // Adjust the thickness as needed
                    ),
                  ),
                ],
              ),
            ),
            ...budgetList.map((budgetName) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      openBudget(budgetName);
                    },
                    child: Text("Open Budget: $budgetName"),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  final Color color =
      Color(int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000);

  List<Color> colorList = greenColorList;

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
        body: Row(
          children: [
            AnimatedContainer(
                duration: Duration(seconds: 2),
                width: 300,
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Column(children: [
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return BudgetCreationPopup(onBudgetCreated:
                                  (Map<String, double> budgetMap,
                                      String budgetName) {
                                // Step 1: Create the budget in Firebase

                                createBudgetInFirebase(Budget(
                                    budgetName: budgetName,
                                    budgetMap: budgetMap,
                                    expenses: [])).then((result) {
                                  if (result == true) {
                                    // Step 2: Update local state after Firebase operation is successful
                                    setState(() {
                                      this.budgetMap = budgetMap;
                                      this.budgetName = budgetName;
                                      budgetCreated = true;
                                      this.budgetList.add(budgetName);
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
                    const SizedBox(
                      height: 15,
                    ),
                    buildBudgetButtons(),
                  ],
                )),
            const VerticalDivider(
              color: Colors.black,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Column(children: <Widget>[
                      Visibility(
                        visible: budgetMap.isNotEmpty,
                        child: Column(
                          children: <Widget>[
                            Visibility(
                              visible: budgetMap.isNotEmpty,
                              child: Center(
                                child: Column(
                                  children: <Widget>[
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            final resp =
                                                await openAddToBudget();
                                            if (resp == null || resp.isEmpty)
                                              return;
                                            print(resp);

                                            setState(() {
                                              if (!dropdownItems
                                                  .contains(actualCategory)) {
                                                dropdownItems.insert(
                                                    dropdownItems.length - 1,
                                                    actualCategory);
                                              }

                                              // Check if the category already exists in the budgetMap
                                              if (budgetMap.containsKey(
                                                  actualCategory)) {
                                                // If it exists, update the existing value
                                                double currentValue =
                                                    budgetMap[actualCategory] ??
                                                        0.0;
                                                double newValue =
                                                    double.parse(resp);
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
                                          child: const Text(
                                              "Add Spending Category",
                                              style: TextStyle()),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 35),
                                    Visibility(
                                      visible: budgetMap.isNotEmpty,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Column(
                                            children: <Widget>[
                                              const SizedBox(height: 35),
                                              BudgetPieChart(
                                                budgetMap: budgetMap,
                                                valuesAdded:
                                                    budgetMap.isNotEmpty,
                                                colorList: colorList,
                                                color: colorList[0],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                          Container(
                                            width: 2,
                                            height: 500,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                          Column(
                                            children: [
                                              BudgetUsageTable(
                                                budget: Budget(
                                                    budgetMap: budgetMap,
                                                    budgetName: budgetName,
                                                    expenses: expenseList),
                                                expensesList: expenseList,
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 35),
                                    Builder(
                                      builder: (BuildContext context) {
                                        return ElevatedButton(
                                          onPressed: openBudgetTable,
                                          child: const Text(
                                              "View/Edit Current Budget",
                                              style: TextStyle()),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 35),
                                  ],
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      ExpenseTracking(
                                        budget: Budget(
                                            budgetMap: budgetMap,
                                            expenses: expenseList,
                                            budgetName: budgetName),
                                        dropdownItems: dropdownItems,
                                        onExpensesListChanged:
                                            (updatedExpensesList) {
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
                            ),
                            const SizedBox(
                              height: 35,
                            ),
                            WishList(
                              budget: Budget(
                                  budgetMap: budgetMap,
                                  budgetName: budgetName,
                                  expenses: expenseList),
                            ),
                            SizedBox(
                              height: 35,
                            ),
                            ElevatedButton(
                              // Add a button to delete the budget
                              child: const Text(
                                "Delete Budget",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                deleteBudget();
                                setState(() {
                                  budgetList.remove(this.budgetName);
                                });
                              },
                            ),
                            const SizedBox(
                              height: 35,
                            )
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ));
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
                deleteBudgetFromFirebase(budgetName).then((success) {
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
                controller: newBudgetNameController,
                decoration: const InputDecoration(labelText: "New Budget Name"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newBudgetName = newBudgetNameController.text;
                updateBudgetNameInFirebase(budgetName, newBudgetName)
                    .then((success) {
                  if (success) {
                    setState(() {
                      budgetList.remove(budgetName);
                      budgetList.add(newBudgetName);
                      budgetName = newBudgetName;
                    });
                  }
                });
                newBudgetNameController.clear();
                Navigator.of(context).pop();
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
                title: const Text("Enter New Category:", style: TextStyle()),
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
              budget: Budget(
                  budgetMap: budgetMap,
                  budgetName: budgetName,
                  expenses: expenseList),
              onBudgetUpdate: (updatedBudgetMap) async {
                bool updateResult =
                    await updateBudgetInFirebase(budgetName, updatedBudgetMap);

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
    updateBudgetInFirebase(budgetName, budgetMap);
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
        color: color,
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
