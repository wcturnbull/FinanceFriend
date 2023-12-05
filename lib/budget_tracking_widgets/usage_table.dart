import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:financefriend/graph_page.dart';
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
  Budget budget;
  List<Expense> expensesList;

  BudgetUsageTable({
    required this.budget,
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
    List<Expense> expenses = await getExpensesFromDB(widget.budget.budgetName);

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
          Container(
              height: (calculateCategoryUsage().length * 48.0 + 118.0)
                  .clamp(400, double.infinity),
              width: 500,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 4,
                margin: const EdgeInsets.all(30),
                child: displayMode == DisplayMode.Table
                    ? buildTable()
                    : displayMode == DisplayMode.PieCharts
                        ? buildPieCharts()
                        : buildDonutCharts(),
              )),
        ],
      ),
    );
  }

  Widget buildTable() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();

    return SingleChildScrollView(
      // Make it scrollable
      child: DataTable(
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text("Category")),
          DataColumn(label: Text("Percentage")),
          DataColumn(label: Text("Dollar Amount")),
          //DataColumn(label: Text("Dollar Allowance"))
        ],
        rows: categoryUsageMap.entries.map((entry) {
          String percentage_str = "${entry.value.toStringAsFixed(2)}%";
          if (entry.value >= 100) {
            percentage_str = "\u26A0\uFE0F Over Budget!";
          }
          return DataRow(cells: [
            DataCell(Text(entry.key)),
            DataCell(Text("${percentage_str}")),
            DataCell(Text(
                "\$${widget.expensesList.where((expense) => expense.category == entry.key).fold(0, (prev, expense) => prev + expense.price.toInt()).toStringAsFixed(2)}")),
            //DataCell(Text("\$${widget.budget.budgetMap[entry.key]}")),
          ]);
        }).toList(),
      ),
    );
  }

  Widget buildPieCharts() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();
    final double totalBudget =
        widget.budget.budgetMap.values.fold(0, (prev, amount) => prev + amount);
    final double totalExpenses =
        widget.expensesList.fold(0, (prev, expense) => prev + expense.price);

    final List<Widget> pieCharts = [];

    final Map<String, double> overallDataMap;
    if (totalExpenses >= 100) {
      overallDataMap = {
        "Spent": 100,
        "Available": 0,
      };
    } else {
      overallDataMap = {
        "Spent": totalExpenses,
        "Available": totalBudget - totalExpenses,
      };
    }

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
        final Map<String, double> dataMap;
        if (usage <= 100) {
          dataMap = {
            "Spent": usage,
            "Available": 100 - usage,
          };
        } else {
          dataMap = {
            "Spent": 100,
            "Available": 0,
          };
        }
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: pieCharts,
      ),
    );
  }

  Widget buildDonutCharts() {
    final Map<String, double> categoryUsageMap = calculateCategoryUsage();
    final double totalBudget =
        widget.budget.budgetMap.values.fold(0, (prev, amount) => prev + amount);
    final double totalExpenses =
        widget.expensesList.fold(0, (prev, expense) => prev + expense.price);

    final List<Widget> donutCharts = [];

    // Create a chart for overall expenses vs. overall budget
    final Map<String, double> overallDataMap;
    if (totalExpenses >= 100) {
      overallDataMap = {
        "Spent": 100,
        "Available": 0,
      };
    } else {
      overallDataMap = {
        "Spent": totalExpenses,
        "Available": totalBudget - totalExpenses,
      };
    }

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
              Colors.red,
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
      String usage_str = usage.toStringAsFixed(2) + "%";
      if (usage > 0) {
        final Map<String, double> dataMap;
        List<Color> colorList = [];
        if (usage <= 100) {
          dataMap = {
            "Spent": usage,
            "Available": 100 - usage,
          };
        } else {
          usage = 100;
          usage_str = "\u26A0\uFE0F\n>100%";
          dataMap = {
            "Spent": usage,
            "Available": 100 - usage,
          };
        }
        if (usage <= 49) {
          colorList = [Colors.green, Colors.transparent];
        } else if (usage <= 74) {
          colorList = [Colors.yellow, Colors.transparent];
        } else if (usage <= 89) {
          colorList = [Colors.orange, Colors.transparent];
        } else {
          colorList = [Colors.red, Colors.transparent];
        }
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
                chartRadius: 80,
                initialAngleInDegree: 0,
                chartType: ChartType.ring,
                ringStrokeWidth: 20,
                colorList: colorList,
                centerText: "${usage_str}",
                legendOptions: LegendOptions(showLegends: false),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValues: false,
                  showChartValuesInPercentage: false,
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: donutCharts,
      ),
    );
  }

  Map<String, double> calculateCategoryUsage() {
    final Map<String, double> categoryUsageMap = {};

    widget.budget.budgetMap.forEach((category, budgetAmount) {
      double expensesAmount = widget.expensesList
          .where((expense) => expense.category == category)
          .fold(0, (prev, expense) => prev + expense.price);
      double categoryPercentage = (expensesAmount / budgetAmount) * 100;
      categoryUsageMap[category] = categoryPercentage;
    });

    return categoryUsageMap;
  }
}
