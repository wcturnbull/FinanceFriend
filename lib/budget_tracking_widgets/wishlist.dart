import 'dart:math';

import 'package:financefriend/budget_tracking_widgets/budget.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/budget_tracking_widgets/budget_creation.dart';
import 'package:financefriend/budget_tracking_widgets/expense_tracking.dart';
import 'package:financefriend/budget_tracking_widgets/budget_db_utils.dart';

class WishList extends StatefulWidget {
  Budget budget;
  List<WishListItem> wishlist;

  WishList({required this.budget, required this.wishlist});

  @override
  _WishListState createState() => _WishListState();
}

class _WishListState extends State<WishList> {
  @override
  void initState() {
    super.initState();
    loadWishlistFromDB();
  }

  Future<void> loadWishlistFromDB() async {
    List<WishListItem> wishlist = await getWishlistFromDB();

    setState(() {
      widget.wishlist = wishlist;
    });
  }

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    super.dispose();
  }

  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 20,
        color: Colors.green,
        margin: const EdgeInsets.all(30),
        child: Column(children: [
          const SizedBox(height: 10),
          const Text("Wishlist",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: () {
                  _openAddWishListItem(context);
                },
                child: const Text("Add Wishlist Item")),
            const SizedBox(width: 10),
          ]),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(30),
            child: Visibility(
              visible: widget.wishlist.isNotEmpty,
              child: SizedBox(
                child: SingleChildScrollView(
                  child: WishlistDataTable(
                    wishlist: widget.wishlist,
                    onEditWish: _editWishlistItem,
                    onDeleteWish: _deleteWishlistItem,
                  ),
                ),
              ),
            ),
          ),
        ]));
  }

  void _editWishlistItem(BuildContext context, int index) {
    WishListItem item = widget.wishlist[index];
    TextEditingController nameController =
        TextEditingController(text: item.itemName);
    TextEditingController priceController =
        TextEditingController(text: item.price.toStringAsFixed(2));
    TextEditingController progressController =
        TextEditingController(text: item.progress.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Wishlist Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Price (in dollars)'),
              ),
              TextFormField(
                controller: progressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Progress (in dollars)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.wishlist[index].itemName = nameController.text;
                  widget.wishlist[index].price =
                      double.parse(priceController.text);
                  widget.wishlist[index].progress =
                      double.parse(progressController.text);
                });
                saveWishlistToFirebase(widget.wishlist);
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteWishlistItem(int index) {
    widget.wishlist.removeAt(index);

    saveWishlistToFirebase(widget.wishlist);

    setState(() {});
  }

  Future<void> _openAddWishListItem(BuildContext context) async {
    itemController.clear();
    priceController.clear();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Wishlist"),
              TextFormField(
                controller: itemController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
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
                widget.wishlist.add(WishListItem(
                    itemName: itemController.text,
                    progress: 0.0,
                    price: (double.parse(priceController.text))));
                saveWishlistToFirebase(widget.wishlist);
                setState(() {
                  widget.wishlist = widget.wishlist;
                });
                itemController.clear();
                priceController.clear();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}

class WishListItem {
  String itemName;
  double price;
  double progress = 0;

  WishListItem({
    required this.itemName,
    required this.price,
    required this.progress,
  });
}

class WishlistDataTable extends StatefulWidget {
  List<WishListItem> wishlist;
  Function(BuildContext, int) onEditWish;
  Function(int) onDeleteWish;

  WishlistDataTable({
    required this.wishlist,
    required this.onDeleteWish,
    required this.onEditWish,
  });

  @override
  _WishlistDataTableState createState() => _WishlistDataTableState();
}

class _WishlistDataTableState extends State<WishlistDataTable> {
  List<DataColumn> columns = [
    const DataColumn(
      label: Text('Item'),
    ),
    const DataColumn(
      label: Text('Price'),
      numeric: true,
    ),
    const DataColumn(
      label: Text('Progress'),
    ),
    const DataColumn(label: Text('Amount Needed')),
    const DataColumn(
      label: Text('Actions'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Visibility(
          visible: widget.wishlist.isNotEmpty,
          child: DataTable(
            columns: columns,
            rows: widget.wishlist.isEmpty
                ? [
                    const DataRow(
                        cells: [DataCell(Text('No items in wishlist'))])
                  ]
                : generateExpenseRows(widget.wishlist),
          ),
        ),
      ],
    );
  }

  List<DataRow> generateExpenseRows(List<WishListItem> wishlist) {
    List<DataRow> rows = [];

    for (int i = 0; i < wishlist.length; i++) {
      WishListItem wsh_item = wishlist[i];
      double progress_pct = (wsh_item.progress / wsh_item.price) * 100;
      String progress_pct_string = "${((progress_pct).toStringAsFixed(2))}%";
      double amt_needed = wsh_item.price - wsh_item.progress;
      bool reached = false;

      if (progress_pct_string == "100.00%" || progress_pct > 100) {
        progress_pct_string = "\u2714";
        amt_needed = 0;
        reached = true;
      }

      rows.add(DataRow(
        cells: [
          DataCell(Text(wsh_item.itemName)),
          DataCell(Text('\$${wsh_item.price.toStringAsFixed(2)}')),
          DataCell(Text('${progress_pct_string}')),
          DataCell(Text('\$${amt_needed}')),
          DataCell(
            Row(
              children: [
                Visibility(
                  visible: !reached,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      widget.onEditWish(context, i);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onDeleteWish(i); // Delete the item
                  },
                ),
                Visibility(
                  visible: !reached,
                  child: ElevatedButton(
                    child: Text("Add Funds"),
                    onPressed: () {
                      _addFunds(context, i); // Add funds to the item
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ));
    }

    return rows;
  }

  void _addFunds(BuildContext context, int index) {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Funds"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  double amount = double.parse(amountController.text);
                  widget.wishlist[index].progress += amount; // Update progress
                });
                saveWishlistToFirebase(widget.wishlist);
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}
