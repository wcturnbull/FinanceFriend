import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

class InvestmentPage extends StatefulWidget {
  @override
  _InvestmentPageState createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  List<Map<String, dynamic>> investments = [];

  List<DataRow> investmentsTableRows = [];

  DataTable investmentsDataTable = DataTable(
    columns: [
      DataColumn(label: Text('Stock Name')),
      DataColumn(label: Text('Date Purchased')),
      DataColumn(label: Text('Amount')),
      DataColumn(label: Text('Price')),
    ],
    rows: [],
  );

  @override
  Widget build(BuildContext context) {
    double total = investments.fold(0.0, (sum, investment) {
      return sum + double.parse(investment['Price']);
    });

    String totalFormatted = total.toStringAsFixed(2);

    DataRow totalRow = DataRow(cells: [
      DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text('')),
      DataCell(Text('')),
      DataCell(
          Text(totalFormatted, style: TextStyle(fontWeight: FontWeight.bold))),
    ]);

    investmentsTableRows = investments.map((investment) {
      return DataRow(cells: [
        DataCell(Text(investment['Stock Name'])),
        DataCell(Text(investment['Date Purchased'])),
        DataCell(Text(investment['Amount'])),
        DataCell(Text(investment['Price'])),
      ]);
    }).toList();

    investmentsTableRows.add(totalRow);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
          style: TextStyle(color: Colors.black, fontSize: 15),
        ),
        backgroundColor: Colors.green,
        flexibleSpace: Center(
          child: Text(
            'Investment Page',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Add Investment'),
                            content: FormBuilder(
                              key: _fbKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  FormBuilderDropdown(
                                    name: 'investmentOption',
                                    items: List.generate(
                                      10,
                                      (index) => DropdownMenuItem(
                                        value: (index + 1).toString(),
                                        child: Text((index + 1).toString()),
                                      ),
                                    ),
                                  ),
                                  FormBuilderTextField(
                                    name: 'price',
                                    decoration:
                                        InputDecoration(labelText: 'Price'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  FormBuilderTextField(
                                    name: 'amount',
                                    decoration:
                                        InputDecoration(labelText: 'Amount'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (_fbKey.currentState!.saveAndValidate()) {
                                    final formData = _fbKey.currentState!.value;

                                    final currentDate = DateFormat('yyyy-MM-dd')
                                        .format(DateTime.now());

                                    setState(() {
                                      investments.add({
                                        'Stock Name':
                                            formData['investmentOption'],
                                        'Date Purchased': currentDate,
                                        'Amount': formData['amount'],
                                        'Price': formData['price'],
                                      });
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('Save'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('Add Investments'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Code for "Button 2"
                    },
                    child: Text('More Information'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Code for "Button 3"
                    },
                    child: Text('Generate Graph'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (investments.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Stock Name')),
                      DataColumn(label: Text('Date Purchased')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Price')),
                    ],
                    rows: investmentsTableRows,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
