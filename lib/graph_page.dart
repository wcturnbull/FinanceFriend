import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

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
  bool isFormValid = false; // Initialize with a default category

  Map<String, double> budgetMap = {
    "Housing": 0,
    "Utilities": 0,
    "Food": 0,
    "Transportation": 0,
    "Entertainment": 0,
    "Investments": 0,
    "Debt Payments": 0
  };

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
    "Other",
  ];

  TextEditingController customCategoryController = TextEditingController();
  bool isOtherSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Budget Allocation'),
      ),
      body: Column(
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
                    budgetMap.addAll({actualCategory: double.parse(resp)});
                    values_added = true;
                  });
                  print(budgetMap);
                },
                child: Text("Add Spending Category"),
              );
            },
          ),
          SizedBox(height: 35),
          BudgetPieChart(
            budgetMap: budgetMap,
            valuesAdded: values_added,
            colorList: colorList,
            color: color,
          ),
          SizedBox(height: 35),
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: openBudgetTable,
                child: Text("View Current Budget"),
              );
            },
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<String?> openAddToBudget() => showDialog<String>(
        context: scaffoldKey.currentContext!,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Enter Expense:"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: dropdownItems.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                          isFormValid =
                              newValue != "Select Category" && !isOtherSelected;
                          // Check if "Other" is selected
                          isOtherSelected = newValue == "Other";
                        });
                      },
                    ),
                    // Show a text field if "Other" is selected
                    if (isOtherSelected)
                      TextField(
                        controller: customCategoryController,
                        decoration: InputDecoration(
                          hintText: 'Enter a custom category',
                        ),
                      ),
                    SizedBox(height: 10), // Add some spacing
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your expense amount (i.e. \$25)',
                      ),
                      controller: controller,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      submit();
                      // Update values_added when a custom category is added
                      // if (isOtherSelected) {
                      setState(() {
                        values_added = true;
                      });
                      // }
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text("Submit"),
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
        return BudgetTable(budgetMap: budgetMap);
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
        budgetMap[actualCategory] =
            (budgetMap[actualCategory]! + double.parse(controller.text))!;
      });
      selectedCategory = "Select Category";
    }
    controller.clear();
    customCategoryController.clear(); // Clear the custom category input
  }

  double getTotalBudget(Map<String, double> budgetMap) {
    double total = budgetMap.values.fold(0, (previousValue, currentValue) {
      return previousValue + currentValue;
    });

    return double.parse(total.toStringAsFixed(2));
  }
}

class BudgetTable extends StatelessWidget {
  final Map<String, double> budgetMap;

  BudgetTable({required this.budgetMap});

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;

    // Calculate the total amount
    budgetMap.values.forEach((amount) {
      totalAmount += amount;
    });

    return AlertDialog(
      title: Text(
        "Current Budget",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListView.builder(
              itemCount: budgetMap.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final category = budgetMap.keys.toList()[index];
                final amount = budgetMap[category];
                return ListTile(
                  title: Text(category, style: TextStyle(fontSize: 18.5)),
                  subtitle: Text(
                    "\$$amount",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
            // Display the total amount at the bottom
            SizedBox(height: 2),
            Center(
                child: Text(
              "Total: \$${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text("Close"),
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
    return PieChart(
      key: UniqueKey(),
      dataMap: budgetMap,
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 80,
      chartRadius: 300,
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 35,
      centerText: "\$" + getTotalBudget(budgetMap).toString(),
      centerTextStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 40,
        background: Paint()
          ..strokeWidth = 25.0
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValueBackground: false,
        showChartValues: valuesAdded,
        showChartValuesInPercentage: true,
        decimalPlaces: 0,
      ),
      legendOptions: valuesAdded
          ? LegendOptions(
              showLegends: true,
              legendPosition: LegendPosition.right,
              legendTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : LegendOptions(
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
