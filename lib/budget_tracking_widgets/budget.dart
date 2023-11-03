import 'dart:ui';

import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';

class Budget {
  String budgetName;
  Map<String, double> budgetMap;
  List<Expense> expenses;
  List<Color> colorList;

  Budget({
    required this.budgetName,
    required this.budgetMap,
    required this.expenses,
    required this.colorList,
  });
}
