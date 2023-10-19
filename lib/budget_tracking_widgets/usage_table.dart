import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_creation.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';

class BudgetUsageTable extends StatefulWidget {
  final Map<String, double> budgetMap;
  List<Expense> expensesList;

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
  void initState() {
    super.initState();
    loadExpensesFromFirebase();
  }

  Future<void> loadExpensesFromFirebase() async {
    List<Expense> expenses = await getExpensesFromDB();

    setState(() {
      widget.expensesList = expenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 20,
      color: Colors.green,
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Budget Usage",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Add buttons to switch between display modes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 5,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.Table;
                  });
                },
                child: const Text("Table"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.PieCharts;
                  });
                },
                child: const Text("Pie Charts"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    displayMode = DisplayMode.DonutChart;
                  });
                },
                child: const Text("Ring Chart"), // Add Histogram button
              ),
              const SizedBox(
                width: 5,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(30),
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
        const DataColumn(label: Text("Category")),
        const DataColumn(label: Text("Percentage")),
        const DataColumn(label: Text("Dollar Amount")),
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
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Overall Budget",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChart(
            dataMap: overallDataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 80,
            chartRadius: 100,
            initialAngleInDegree: 0,
            ringStrokeWidth: 20,
            centerTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            colorList: [
              Color(
                  int.parse("#871224".substring(1, 7), radix: 16) + 0xFF000000),
              Colors.green,
            ],
            // centerText:
            //     "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
            chartValuesOptions: const ChartValuesOptions(
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              PieChart(
                dataMap: dataMap,
                animationDuration: const Duration(milliseconds: 800),
                chartLegendSpacing: 80,
                chartRadius: 100,
                initialAngleInDegree: 0,
                centerTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                colorList: [
                  Color(int.parse("#871224".substring(1, 7), radix: 16) +
                      0xFF000000),
                  Colors.green,
                ],
                // centerText:
                //     "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
                chartValuesOptions: const ChartValuesOptions(
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
      return const Text("No data to display");
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
      margin: const EdgeInsets.all(10), // 20px margin around the donut chart
      child: Column(
        children: [
          const Text(
            "Overall Budget",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          PieChart(
            dataMap: overallDataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 80,
            chartRadius: 80,
            initialAngleInDegree: 0,
            chartType: ChartType.ring,
            ringStrokeWidth: 20,
            colorList: [
              Color(
                  int.parse("#871224".substring(1, 7), radix: 16) + 0xFF000000),
              Colors.green,
            ],
            centerText:
                "${(totalExpenses / totalBudget * 100).toStringAsFixed(2)}%",
            chartValuesOptions: const ChartValuesOptions(
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
          margin:
              const EdgeInsets.all(10), // 20px margin around the donut chart
          child: Column(
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              PieChart(
                dataMap: dataMap,
                animationDuration: const Duration(milliseconds: 800),
                chartLegendSpacing: 80,
                chartRadius: 80,
                initialAngleInDegree: 0,
                chartType: ChartType.ring,
                ringStrokeWidth: 20,
                colorList: [
                  Color(int.parse("#871224".substring(1, 7), radix: 16) +
                      0xFF000000),
                  Colors.green,
                ],
                centerText: "${usage.toStringAsFixed(2)}%",
                chartValuesOptions: const ChartValuesOptions(
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
      return const Text("No data to display");
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
