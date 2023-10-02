import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late TextEditingController controller;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String actualCategory = "";
  bool values_added = false;

  String selectedCategory = "Select Category";
  bool isFormValid = false;
  bool budgetCreated = false;

  // Map<String, double> budgetMap = {
  //   "Housing": 0,
  //   "Utilities": 0,
  //   "Food": 0,
  //   "Transportation": 0,
  //   "Entertainment": 0,
  //   "Investments": 0,
  //   "Debt Payments": 0
  // };

  Map<String, double> budgetMap = {};
  double budgetAmount = 0;

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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: !budgetCreated,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return BudgetCreationPopup(
                          onBudgetCreated: (Map<String, double> budgetMap) {
                            // Set budgetMap and update visibility
                            setState(() {
                              this.budgetMap = budgetMap;
                              budgetCreated = true;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: Text("Create Budget"),
                ),
              ),
              // Visibility(
              //     visible: afterBudgetAmt,
              //     // SHOULD BUILD UP THE BUDGETCREATIONPOPUP
              //     child: SizedBox()),
              Visibility(
                visible:
                    budgetCreated, // Show the chart only when budgetMap is not empty
                child: Column(
                  children: <Widget>[
                    Builder(
                      builder: (BuildContext context) {
                        return ElevatedButton(
                          onPressed: () async {
                            final resp = await openAddToBudget();
                            if (resp == null || resp.isEmpty) return;
                            print(resp);
                            setState(() {
                              if (!dropdownItems.contains(actualCategory)) {
                                // Add the custom category to the dropdown items
                                dropdownItems.insert(
                                    dropdownItems.length - 1, actualCategory);
                              }
                              budgetMap
                                  .addAll({actualCategory: double.parse(resp)});
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
                      child: Column(children: <Widget>[
                        const SizedBox(height: 35),
                        BudgetPieChart(
                          budgetMap: budgetMap,
                          valuesAdded: budgetMap.isNotEmpty,
                          colorList: colorList,
                          color: color,
                        ),
                      ]),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
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

  void createBudgetPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return BudgetCreationPopup(
          onBudgetCreated: (Map<String, double> budgetMap) {
            // Set budgetMap and update visibility
            setState(() {
              this.budgetMap = budgetMap;
              budgetCreated = true;
              print(budgetMap);
            });
          },
        );
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

    String editedCategory =
        category; // Initialize with the current category name

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

class BudgetAmountDialog extends StatefulWidget {
  final Function(double) budgetAmount;

  BudgetAmountDialog({required this.budgetAmount});

  @override
  _BudgetAmountDialogState createState() => _BudgetAmountDialogState();
}

class _BudgetAmountDialogState extends State<BudgetAmountDialog> {
  TextEditingController amountController = TextEditingController();
  double budgetAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Enter Budgeting Amount"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                budgetAmount = double.tryParse(value) ?? 0.0;
              });
            },
            decoration: InputDecoration(labelText: "Budgeting Amount"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog

            if (budgetAmount > 0) {
              // widget.onBudgetCreated({"Custom": budgetAmount});
              widget.budgetAmount(budgetAmount);
              // Optionally, you can set values_added to true here
              // setState(() {
              //   values_added = true;
              // });
            }
          },
          child: Text("Continue"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
}

class BudgetCreationPopup extends StatefulWidget {
  final void Function(Map<String, double>) onBudgetCreated;

  BudgetCreationPopup({required this.onBudgetCreated});

  @override
  _BudgetCreationPopupState createState() => _BudgetCreationPopupState();
}

class _BudgetCreationPopupState extends State<BudgetCreationPopup> {
  List<BudgetItem> budgetItems = [
    BudgetItem(categoryName: "", percentage: 0.0)
  ]; // Initialize with one item

  Map<String, double> budgetMap = {}; // Initialize the budgetMap

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Create Budget"),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                  );
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
                double totalPercentage = 0;
                for (var item in budgetItems) {
                  totalPercentage += item.percentage;
                }

                //if (totalPercentage == 100) {
                // Close the popup and send the created budget back
                Navigator.of(context).pop();

                // Process the budgetItems list here
                // You can access category names and percentages from budgetItems

                // Update the budgetMap with the category and slider value
                for (var item in budgetItems) {
                  budgetMap[item.categoryName] =
                      item.percentage.roundToDouble();
                }

                print(budgetMap);
                widget.onBudgetCreated(budgetMap);
                // } else {
                //   // Show an error message or handle the case where percentages don't add up to 100
                // }
              },
              child: Text("Make Budget"),
            ),
          ],
        ),
      ),
    );
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

  BudgetItemInput({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
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
                    "${widget.item.percentage.toStringAsFixed(2)}%", // Display the percentage value
                    style: TextStyle(
                        fontSize: 12), // Adjust the font size as needed
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
      ],
    );
  }
}
