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
    Color(int.parse("#248712".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#33921C".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#439D27".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#54A931".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#66B53B".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#79C046".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#8CDB50".substring(1, 7), radix: 16) + 0xFF0000000),
    Color(int.parse("#A0E75A".substring(1, 7), radix: 16) + 0xFF0000000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Graph Page'),
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
                    budgetMap.addAll({actualCategory: double.parse(resp)});
                    values_added =
                        true; // Set values_added to true when anything is added
                  });
                  print(budgetMap);
                },
                child: Text("Add Spending Category"),
              );
            },
          ),
          SizedBox(height: 35),
          PieChart(
            key: UniqueKey(), // Add a unique key to the PieChart widget
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
              showChartValues:
                  values_added, // Show values when anything is added
              showChartValuesInPercentage: true,
              decimalPlaces: 0,
            ),
            legendOptions: values_added
                ? LegendOptions(
                    showLegends: true,
                    legendPosition: LegendPosition.right,
                    legendTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : LegendOptions(
                    showLegends: false), // Hide legends when nothing is added
            baseChartColor: Colors.white,
            colorList: colorList,
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
          return AlertDialog(
            title: const Text("Enter Expense:"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    "Select Category",
                    "Housing",
                    "Utilities",
                    "Food",
                    "Transportation",
                    "Entertainment",
                    "Investments",
                    "Debt Payments"
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      isFormValid =
                          newValue != "Select Category"; // Update form validity
                    });
                  },
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
              TextButton(onPressed: submit, child: const Text("Submit"))
            ],
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
    if (selectedCategory != "Select Category") {
      budgetMap.addAll({selectedCategory: double.parse(controller.text)});
      values_added = true; // Set values_added to true when anything is added
      Navigator.of(context).pop(controller.text);
      selectedCategory = "Select Category";
    }
    controller.clear();
  }

  double getTotalBudget(Map<String, double> budgetMap) {
    return budgetMap.values.fold(0,
        (double previousValue, double currentValue) {
      return previousValue + currentValue;
    });
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
