import 'package:financefriend/budget_tracking_widgets/budget.dart';
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

Future<List<Expense>> getExpensesFromDB() async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return []; // Return an empty list or an appropriate default value
  }

  try {
    final budgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetData/expenses');

    // Fetch the expenses data from Firebase
    DataSnapshot snapshot = (await budgetReference.once()).snapshot;

    if (snapshot.value != null) {
      final List<dynamic> expensesData = snapshot.value as List<dynamic>;

      // Convert the Firebase data into a list of Expense objects
      List<Expense> expensesList = expensesData.map((data) {
        if (data is Map<String, dynamic>) {
          return Expense(
            item: data['item'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            category: data['category'] ?? '',
            date: data['date'] ?? '',
          );
        }
        return Expense(item: '', price: 0.0, category: '', date: '');
      }).toList();

      return expensesList;
    } else {
      // Handle the case where the data does not exist
      return []; // Return an empty list or an appropriate default value
    }
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error fetching expenses from Firebase: $error");
    return []; // Return an empty list or an appropriate default value
  }
}

Future<bool> saveExpensesToFirebase(List<Expense> expenses) async {
  if (currentUser == null) {
    return false;
  }

  try {
    final expensesReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetData/expenses');

    final List<Map<String, dynamic>> expensesData = expenses.map((expense) {
      return {
        'item': expense.item,
        'price': expense.price,
        'category': expense.category,
        'date': expense.date,
      };
    }).toList();

    await expensesReference.set(expensesData);

    return true; // Operation successful
  } catch (error) {
    print("Error saving expenses to Firebase: $error");
    return false;
  }
}

Future<Budget> getBudgetFromFirebase() async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return Budget(
        budgetName: "",
        budgetMap: {},
        expenses: []); // Return an empty Budget object with empty expenses or an appropriate default value
  }

  try {
    final budgetDataRef =
        reference.child('users/${currentUser?.uid}/budgets/budgetData');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetDataRef.once();
    DataSnapshot snapshot = event.snapshot;

    // Check if the data exists
    if (snapshot.value != null) {
      // Use explicit type casting to ensure all values are of type double
      Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;

      String budgetName = dataMap['budgetName'] ?? "";
      Map<String, dynamic> budgetData = dataMap['budgetMap'] ?? {};

      List<Expense> expensesList =
          (dataMap['expenses'] as List<dynamic>).map((data) {
        if (data is Map<String, dynamic>) {
          return Expense(
            item: data['item'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            category: data['category'] ?? '',
            date: data['date'] ?? '',
          );
        }
        return Expense(item: '', price: 0.0, category: '', date: '');
      }).toList();

      Map<String, double> budgetMap = {};
      budgetData.forEach((key, value) {
        if (value is double) {
          budgetMap[key] = value;
        } else if (value is int) {
          budgetMap[key] = value.toDouble();
        } else if (value is String) {
          budgetMap[key] = double.tryParse(value) ?? 0.0;
        }
      });

      return Budget(
          budgetName: budgetName, budgetMap: budgetMap, expenses: expensesList);
    } else {
      // Handle the case where the data does not exist
      return Budget(
          budgetName: "",
          budgetMap: {},
          expenses: []); // Return an empty Budget object with empty expenses or an appropriate default value
    }
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error fetching budget data from Firebase: $error");
    return Budget(
        budgetName: "",
        budgetMap: {},
        expenses: []); // Return an empty Budget object with empty expenses or an appropriate default value
  }
}

Future<String> getBudgetNameFromFirebase() async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return ""; // Return an empty map or an appropriate default value
  }

  try {
    final budgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetData/budgetName');

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

Future<bool> createBudgetInFirebase(Budget budget) async {
  // final reference = FirebaseDatabase.instance.reference();
  // final currentUser = FirebaseAuth.instance.currentUser;
  print("Putting data in database");

  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final newBudgetReference =
        reference.child('users/${currentUser?.uid}/budgets/budgetData');

    // Store the budgetMap under the unique key
    await newBudgetReference.child("budgetMap").set(budget.budgetMap);

    // Optionally, you can store the budgetName as well
    await newBudgetReference.child('budgetName').set(budget.budgetName);
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
        reference.child('users/${currentUser?.uid}/budgets/budgetData');

    // Update the budgetMap with the new data
    await budgetReference.child("budgetMap").update(updatedBudgetMap);

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
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgets');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetReference.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.hasChild("budgetData")) {
      final budgetMapReference =
          reference.child('users/${currentUser?.uid}/budgets/budgetData');
      DatabaseEvent event2 = await budgetMapReference.once();
      DataSnapshot snapshot2 = event2.snapshot;
      if (snapshot2.hasChild("budgetName") && snapshot2.hasChild("budgetMap")) {
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
        .child('users/${currentUser?.uid}/budgets/budgetData/budgetName');

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
        reference.child('users/${currentUser?.uid}/budgets/budgetData');

    // Delete the budgetData and budgetName nodes
    await budgetReference.child("budgetMap").remove();
    await budgetReference.child('budgetName').remove();
    await budgetReference.child("expenses").remove();

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error deleting budget from Firebase: $error");
    return false;
  }
}

Future<bool> removeBudgetCategory(String categoryName) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final newBudgetReference = reference
        .child('users/${currentUser?.uid}/budgets/budgetData/budgetMap');

    print("trying to remove: " + categoryName);

    await newBudgetReference.child(categoryName).remove();

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error creating budget in Firebase: $error");
    return false;
  }
}
