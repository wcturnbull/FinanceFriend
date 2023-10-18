import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final budgetReference =
        reference.child('users/${currentUser?.uid}/budgetMap/expenses');

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
    final expensesReference =
        reference.child('users/${currentUser?.uid}/budgetMap/expenses');

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

class ExpenseTracking extends StatefulWidget {
  final Map<String, double> budgetMap;
  final List<String> dropdownItems;
  List<Expense> expensesList;
  final Function(List<Expense>) onExpensesListChanged; // Add this callback

  ExpenseTracking({
    required this.budgetMap,
    required this.dropdownItems,
    required this.expensesList,
    required this.onExpensesListChanged, // Initialize the callback
  });

  @override
  _ExpenseTrackingState createState() => _ExpenseTrackingState();
}

class _ExpenseTrackingState extends State<ExpenseTracking> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedCategory = "Select Category";
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
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 20,
      color: Colors.green,
      margin: const EdgeInsets.all(30),
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Expenses List",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () {
                addDefaultExpenses(context);
                setState(() {});
              },
              child: const Text("[TESTING] auto populate transactions")),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  _openAddExpenseDialog(context);
                },
                child: const Text("Enter New Expense"),
              ),
              const SizedBox(
                width: 10,
              )
            ],
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(30),
            child: Visibility(
              visible: widget.expensesList.isNotEmpty,
              child: SizedBox(
                width: 700,
                height: 360,
                child: SingleChildScrollView(
                  child: BudgetDataTable(
                    expenseList: widget.expensesList,
                    onEditExpense: _onEditExpense, // Pass the edit function
                    onDeleteExpense:
                        _onDeleteExpense, // Pass the delete function
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addDefaultExpenses(BuildContext context) {
    widget.expensesList.add(Expense(
        item: "McDonalds",
        price: 10,
        category: "Food",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Panda Express",
        price: 12,
        category: "Food",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "CFA Catering",
        price: 120,
        category: "Food",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Water Bill",
        price: 40,
        category: "Utilities",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Gas",
        price: 30,
        category: "Transportation",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Movie Tickets",
        price: 25,
        category: "Entertainment",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Stock Investment",
        price: 50,
        category: "Investments",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));
    widget.expensesList.add(Expense(
        item: "Credit Card Payment",
        price: 35,
        category: "Debt Payments",
        date: DateFormat('MM/dd/yyyy').format(DateTime.now())));

    widget.onExpensesListChanged(widget.expensesList);
  }

  Future<void> _openAddExpenseDialog(BuildContext context) async {
    selectedCategory = "Select Category";
    itemController.clear();
    priceController.clear();

    // Create a filtered list of dropdown items without "Custom"
    List<String> catNames = widget.budgetMap.keys.toList();
    catNames.insert(0, "Select Category");

    final filteredDropdownItems =
        catNames.where((item) => item != "Custom").toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: itemController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: filteredDropdownItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
              ),
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
                _submitExpense();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _submitExpense() {
    final String item = itemController.text;
    final String price = priceController.text;

    if (item.isNotEmpty &&
        price.isNotEmpty &&
        selectedCategory != "Select Category") {
      double priceValue = double.tryParse(price) ?? 0.0;

      // Create a new Expense object
      Expense newExpense = Expense(
        item: item,
        price: priceValue,
        category: selectedCategory,
        date: DateFormat('MM/dd/yyyy').format(DateTime.now()),
      );

      // Add the newExpense to the expensesList
      widget.expensesList.add(newExpense);
      saveExpensesToFirebase(widget.expensesList);

      // Print the updated expensesList
      print("Expenses List:");
      for (Expense expense in widget.expensesList) {
        print(
            "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
      }

      // Clear text fields and selectedCategory
      itemController.clear();
      priceController.clear();
      selectedCategory = "Select Category";

      widget.onExpensesListChanged(widget.expensesList);

      setState(() {});
    }
  }

  // Function to handle editing an expense
  void _onEditExpense(Expense expenseToEdit) async {
    // Create controllers for editing
    final TextEditingController editedItemController =
        TextEditingController(text: expenseToEdit.item);
    final TextEditingController editedPriceController =
        TextEditingController(text: expenseToEdit.price.toString());
    String editedSelectedCategory = expenseToEdit.category;
    List<String> catNames = widget.budgetMap.keys.toList();
    catNames.insert(0, "Select Category");

    final filteredDropdownItems =
        catNames.where((item) => item != "Custom").toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editedItemController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: editedPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              DropdownButtonFormField<String>(
                value: editedSelectedCategory,
                items: filteredDropdownItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    editedSelectedCategory = newValue!;
                  });
                },
              ),
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
                // Validate and save the edited values
                final String editedItem = editedItemController.text;
                final String editedPrice = editedPriceController.text;

                if (editedItem.isNotEmpty &&
                    editedPrice.isNotEmpty &&
                    editedSelectedCategory != "Select Category") {
                  double editedPriceValue = double.tryParse(editedPrice) ?? 0.0;

                  // Update the values in the expensesList
                  final int indexOfEditedExpense =
                      widget.expensesList.indexOf(expenseToEdit);
                  if (indexOfEditedExpense != -1) {
                    widget.expensesList[indexOfEditedExpense] = Expense(
                      item: editedItem,
                      price: editedPriceValue,
                      category: editedSelectedCategory,
                      date: widget.expensesList[indexOfEditedExpense].date,
                    );
                  }

                  saveExpensesToFirebase(widget.expensesList);

                  // Print the updated expensesList
                  print("Expenses List after editing:");
                  for (Expense expense in widget.expensesList) {
                    print(
                        "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
                  }

                  // Clear text fields and selectedCategory
                  editedItemController.clear();
                  editedPriceController.clear();
                  editedSelectedCategory = "Select Category";

                  setState(() {});
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    widget.onExpensesListChanged(widget.expensesList);
  }

  // Function to handle deleting an expense
  void _onDeleteExpense(Expense expenseToDelete) {
    // Remove the expense from the expensesList
    widget.expensesList.remove(expenseToDelete);

    // Print the updated expensesList
    print("Expenses List after deleting:");
    for (Expense expense in widget.expensesList) {
      print(
          "Item: ${expense.item}, Price: ${expense.price}, Category: ${expense.category}");
    }
    widget.onExpensesListChanged(widget.expensesList);
    saveExpensesToFirebase(widget.expensesList);

    setState(() {});
  }
}

class Expense {
  String item;
  double price;
  String category;
  String date; // Add a DateTime property for the date

  Expense({
    required this.item,
    required this.price,
    required this.category,
    required this.date, // Initialize the date property
  });
}

class BudgetDataTable extends StatefulWidget {
  final List<Expense> expenseList;
  final Function(Expense) onEditExpense;
  final Function(Expense) onDeleteExpense;

  BudgetDataTable({
    required this.expenseList,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  @override
  _BudgetDataTableState createState() => _BudgetDataTableState();
}

class _BudgetDataTableState extends State<BudgetDataTable> {
  List<DataColumn> columns = [
    const DataColumn(
      label: Text('Date'),
    ),
    const DataColumn(
      label: Text('Item'),
    ),
    const DataColumn(
      label: Text('Price'),
      numeric: true,
    ),
    const DataColumn(
      label: Text('Category'),
    ),
    const DataColumn(
      label: Text('Actions'),
    ),
  ];

  bool sortAscending = true;
  int sortColumnIndex = 0;

  // Sorting function
  void sortTable(int columnIndex) {
    setState(() {
      if (columnIndex == sortColumnIndex) {
        sortAscending = !sortAscending;
      } else {
        sortColumnIndex = columnIndex;
        sortAscending = true;
      }

      switch (columnIndex) {
        case 2:
          // Sort by price
          widget.expenseList.sort((a, b) => sortAscending
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price));
          break;
        case 1:
          // Sort by item name
          widget.expenseList.sort((a, b) => sortAscending
              ? a.item.compareTo(b.item)
              : b.item.compareTo(a.item));
          break;
        case 3:
          // Sort by category
          widget.expenseList.sort((a, b) => sortAscending
              ? a.category.compareTo(b.category)
              : b.category.compareTo(a.category));
          break;
        // Handle other columns as needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                sortTable(1); // Sort by Item
              },
              child: const Text('Sort by Item'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                sortTable(2); // Sort by Price
              },
              child: const Text('Sort by Price'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                sortTable(3); // Sort by Category
              },
              child: const Text('Sort by Category'),
            ),
          ],
        ),
        DataTable(
          sortAscending: sortAscending,
          sortColumnIndex: sortColumnIndex,
          columns: columns,
          rows: widget.expenseList.isEmpty
              ? [
                  const DataRow(cells: [DataCell(Text('No expenses'))])
                ]
              : generateExpenseRows(widget.expenseList),
        ),
      ],
    );
  }

  List<DataRow> generateExpenseRows(List<Expense> expenses) {
    List<DataRow> rows = [];

    for (int i = 0; i < expenses.length; i++) {
      Expense expense = expenses[i];
      rows.add(DataRow(
        cells: [
          DataCell(Text(expense.date.toString())),
          DataCell(Text(expense.item)),
          DataCell(Text('\$${expense.price.toStringAsFixed(2)}')),
          DataCell(Text(expense.category)),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    widget.onEditExpense(expense);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onDeleteExpense(expense);
                  },
                ),
              ],
            ),
          ),
        ],
      ));
    }

    return rows;
  }
}
