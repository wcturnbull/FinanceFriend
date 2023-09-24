import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class GraphPage extends StatelessWidget {
  Map<String, double> dataMap1 = {
    "Tuition and Fees": 40,
    "Housing and Utilities": 25,
    "Food and Groceries": 15,
    "Transportation": 5,
    "Textbooks and Supplies": 5,
    "Entertainment and Leisure": 5,
    "Healthcare": 3,
    "Savings and Emergency Fund": 2
  };

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

  GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Page'),
      ),
      body: Center(
        child: PieChart(
          dataMap: dataMap1,
          animationDuration: const Duration(milliseconds: 800),
          chartLegendSpacing: 80,
          chartRadius: 300,
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          ringStrokeWidth: 35,
          centerText: "\$9,000",
          centerTextStyle: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 40,
              background: Paint()
                ..strokeWidth = 25.0
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round),
          chartValuesOptions: const ChartValuesOptions(
            showChartValueBackground: false,
            showChartValues: true,
            showChartValuesInPercentage: true,
            // showChartValuesOutside: true,
            decimalPlaces: 0,
          ),
          baseChartColor: Colors.white,
          colorList: colorList,
        ),
      ),
    );
  }
}
