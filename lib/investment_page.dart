import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class InvestmentPage extends StatefulWidget {
  @override
  _InvestmentPageState createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  List<Map<String, dynamic>> investments = [];

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white, // Text color
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
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Add Investment'),
                        content: FormBuilder(
                          key: _fbKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                decoration: InputDecoration(labelText: 'Price'),
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
                                setState(() {
                                  investments.add({
                                    'Option': formData['investmentOption'],
                                    'Price': formData['price'],
                                    'Amount': formData['amount'],
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
              SizedBox(height: 20),
              if (investments.isNotEmpty)
                DataTable(
                  columns: [
                    DataColumn(label: Text('Stock Name')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Amount')),
                  ],
                  rows: investments.map((investment) {
                    return DataRow(cells: [
                      DataCell(Text(investment['Option'])),
                      DataCell(Text(investment['Price'])),
                      DataCell(Text(investment['Amount'])),
                    ]);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
