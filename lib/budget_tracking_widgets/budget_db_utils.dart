import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:financefriend/budget_tracking_widgets/wishlist.dart';
import 'package:financefriend/graph_page.dart';
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

Future<List<Expense>> getExpensesFromDB(String budgetName) async {
  if (currentUser == null) {
    return [];
  }

  try {
    final budgetReference = reference
        .child('users/${currentUser?.uid}/budgets/$budgetName/expenses');

    DataSnapshot snapshot = (await budgetReference.once()).snapshot;

    if (snapshot.value != null) {
      final List<dynamic> expensesData = snapshot.value as List<dynamic>;

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
      return [];
    }
  } catch (error) {
    print("Error fetching expenses from Firebase: $error");
    return [];
  }
}

Future<List<WishListItem>> getWishlistFromDB() async {
  if (currentUser == null) {
    return [];
  }

  try {
    final budgetReference =
        reference.child('users/${currentUser?.uid}/wishlist');

    DataSnapshot snapshot = (await budgetReference.once()).snapshot;

    if (snapshot.value != null) {
      final List<dynamic> wishlistData = snapshot.value as List<dynamic>;

      List<WishListItem> wishlist = wishlistData.map((data) {
        if (data is Map<String, dynamic>) {
          return WishListItem(
            itemName: data['itemName'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            progress: (data['progress'] ?? 0.0).toDouble(),
          );
        }
        return WishListItem(itemName: "", price: 0.0, progress: 0.0);
      }).toList();

      return wishlist;
    } else {
      return [];
    }
  } catch (error) {
    print("Error fetching expenses from Firebase: $error");
    return [];
  }
}

Future<bool> saveExpensesToFirebase(
    String budgetName, List<Expense> expenses) async {
  print("SAVING EXPENSES TO DB");
  if (currentUser == null) {
    return false;
  }

  try {
    final expensesReference = reference
        .child('users/${currentUser?.uid}/budgets/$budgetName/expenses');
    print(budgetName);

    final List<Map<String, dynamic>> expensesData = expenses.map((expense) {
      return {
        'item': expense.item,
        'price': expense.price,
        'category': expense.category,
        'date': expense.date,
      };
    }).toList();

    await expensesReference.set(expensesData);

    return true;
  } catch (error) {
    print("Error saving expenses to Firebase: $error");
    return false;
  }
}

Future<bool> saveWishlistToFirebase(List<WishListItem> wishlist) async {
  print("SAVING EXPENSES TO DB");
  if (currentUser == null) {
    return false;
  }

  try {
    final expensesReference =
        reference.child('users/${currentUser?.uid}/wishlist');

    final List<Map<String, dynamic>> wishlistData =
        wishlist.map((wishlistItem) {
      return {
        'itemName': wishlistItem.itemName,
        'price': wishlistItem.price,
        'progress': wishlistItem.progress,
      };
    }).toList();

    await expensesReference.set(wishlistData);

    return true;
  } catch (error) {
    print("Error saving expenses to Firebase: $error");
    return false;
  }
}

Future<Budget> getBudgetFromFirebaseByName(String budgetName) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return Budget(
        budgetName: "",
        budgetMap: {},
        expenses: []); // Return an empty Budget object with empty expenses or an appropriate default value
  }

  try {
    final budgetDataRef =
        reference.child('users/${currentUser?.uid}/budgets/$budgetName');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetDataRef.once();
    DataSnapshot snapshot = event.snapshot;

    // Check if the data exists
    if (snapshot.value != null) {
      // Use explicit type casting to ensure all values are of type double
      Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;
      List<Expense> expensesList;

      String budgetName = dataMap['budgetName'] ?? "";
      Map<String, dynamic> budgetData = dataMap['budgetMap'] ?? {};
      if (dataMap['expenses'] != null) {
        expensesList = (dataMap['expenses'] as List<dynamic>).map((data) {
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
      } else {
        expensesList = [];
      }

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

Future<String> getBudgetNameFromFirebaseByRef(String refLocation) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return "";
  }

  try {
    final budgetDataRef =
        reference.child('users/${currentUser?.uid}/budgets/$refLocation');

    // Fetch the budgetMap data from Firebase
    DatabaseEvent event = await budgetDataRef.once();
    DataSnapshot snapshot = event.snapshot;

    Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;

    // Check if the data exists
    if (snapshot.value != null) {
      String budgetName = dataMap['budgetName'] ?? "";

      return budgetName;
    } else {
      // Handle the case where the data does not exist
      return "";
    }
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error fetching budget data from Firebase: $error");
    return ""; // Return an empty Budget object with empty expenses or an appropriate default value
  }
}

Future<bool> createBudgetInFirebase(Budget budget) async {
  if (currentUser == null) {
    return false; // Handle the case where the user is not authenticated
  }

  try {
    // Generate a unique key for the new budget
    final newBudgetReference = reference
        .child('users/${currentUser?.uid}/budgets/${budget.budgetName}');

    // Store the budgetMap under the unique key
    await newBudgetReference.child("budgetMap").set(budget.budgetMap);

    // Optionally, you can store the budgetName as well
    await newBudgetReference.child('budgetName').set(budget.budgetName);

    await newBudgetReference.child('expenses').set(budget.expenses);

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error creating budget in Firebase: $error");
    return false;
  }
}

Future<bool> updateBudgetInFirebase(
    String budgetName, Map<String, double> updatedBudgetMap) async {
  if (currentUser == null) {
    // Handle the case where the user is not authenticated
    return false;
  }

  try {
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgets/$budgetName/');

    // Update the budgetMap with the new data
    await budgetReference.child("budgetMap").update(updatedBudgetMap);

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error updating budget in Firebase: $error");
    return false;
  }
}

Future<bool> updateBudgetNameInFirebase(
    String oldBudgetName, String newBudgetName) async {
  if (currentUser == null) {
    return false; // Handle the case where the user is not authenticated
  }

  try {
    // Create references for the old and new budget locations
    final newBudgetReference =
        reference.child('users/${currentUser?.uid}/budgets/$newBudgetName');

    Budget temp = await getBudgetFromFirebaseByName(oldBudgetName);
    print(temp.expenses);

    // Delete the old budget
    await reference
        .child('users/${currentUser?.uid}/budgets/$oldBudgetName')
        .remove();

    await newBudgetReference.child('budgetName').set(newBudgetName);
    await newBudgetReference.child('budgetMap').set(temp.budgetMap);
    saveExpensesToFirebase(newBudgetName, temp.expenses);

    return true; // Operation successful
  } catch (error) {
    // Handle any errors that occur during Firebase interaction
    print("Error updating budget name in Firebase: $error");
    return false;
  }
}

Future<bool> deleteBudgetFromFirebase(String budgetName) async {
  if (currentUser == null) {
    return false;
  }

  try {
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgets/$budgetName');

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

Future<bool> removeBudgetCategory(
    String budgetName, String categoryName) async {
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
