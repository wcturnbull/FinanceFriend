import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart';

class InvestmentPage extends StatefulWidget {
  @override
  _InvestmentPageState createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  List<Map<String, dynamic>> investments = [];
  String selectedStockName = '';
  String selectedStockSymbol = '';
  String selectedStockInfo = ''; // Define selectedStockInfo here
  String currentStockPrice = '';
  String editedPrice = '';
  String editedAmount = '';
  String editedDatePurchased = '';
  bool showCurrentPrice = false;
  String historicalPrice = '';
  String percentChange = '';
  String selectedInterval = '1min';

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

  bool showPieChart = false;
  Map<String, double> pieChartData = {
    'Sample 1': 100.0, // Example data, you can add more entries
    'Sample 2': 200.0,
    'Sample 3': 150.0,
  };

  void generatePieChartData() {
    pieChartData.clear();
    double totalInvestment = investments.fold(0.0, (sum, investment) {
      return sum +
          (double.parse(investment['Price']) *
              double.parse(investment['Amount']));
    });

    for (var investment in investments) {
      double investmentValue = (double.parse(investment['Price']) *
          double.parse(investment['Amount']));
      double percentage = (investmentValue / totalInvestment) * 100;
      pieChartData[investment['Stock Name']] = percentage;
    }
  }

  void togglePieChart() {
    setState(() {
      showPieChart = !showPieChart;
    });
  }

  Future<void> fetchStockData(String symbol) async {
    final apiKey = "TGR3PH742VJ1G95V";
    final url = Uri.parse(
        "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=5min&apikey=$apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final timeSeries = jsonResponse['Time Series (5min)'];
      final latestData = timeSeries.values.first;
      final price = latestData['1. open'];

      setState(() {
        currentStockPrice = price;
      });
    } else {
      print('Failed to fetch stock data');
    }
  }

  Future<void> fetchHistoricalStockData(String symbol, String interval) async {
    final apiKey = "TGR3PH742VJ1G95V";
    final url = Uri.parse(
        "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=$interval&apikey=$apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final timeSeries = jsonResponse['Time Series ($interval)'];
      final latestData = timeSeries.values.first;
      final latestPrice = double.parse(latestData['1. open']);
      final historicalData = timeSeries.values.last;
      final historicalPrice = double.parse(historicalData['1. open']);

      final change = latestPrice - historicalPrice;
      final percentChange = (change / historicalPrice * 100).toStringAsFixed(2);

      setState(() {
        this.historicalPrice = historicalPrice.toStringAsFixed(2);
        this.percentChange = '$percentChange%';
      });
    } else {
      print('Failed to fetch historical stock data');
    }
  }

  void showAddInvestmentsDialog(BuildContext context) {
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
                  name: 'stockOption',
                  decoration: InputDecoration(labelText: 'Stock'),
                  items: stocks.map((stock) {
                    return DropdownMenuItem(
                      value: stock['1. symbol'],
                      child: Text(stock['1. symbol']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStockSymbol = value!;
                    });
                  },
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await fetchStockData(selectedStockSymbol);
                    _fbKey.currentState!.fields['price']
                        ?.didChange(currentStockPrice);
                  },
                  child: Text('Confirm'),
                ),
                FormBuilderTextField(
                  name: 'price',
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  initialValue: showCurrentPrice ? currentStockPrice : '',
                ),
                FormBuilderTextField(
                  name: 'amount',
                  decoration: InputDecoration(labelText: 'Amount'),
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
                  final currentDate =
                      DateFormat('yyyy-MM-dd').format(DateTime.now());

                  setState(() {
                    investments.add({
                      'Stock Name': formData['stockOption'],
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
  }

  void showMoreInformationDialog(BuildContext context) {
    final stockSymbolNames = investments.map((investment) {
      return investment['Stock Name'];
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('More Information'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderDropdown(
                    name: 'selectedStock',
                    decoration: InputDecoration(labelText: 'Select Investment'),
                    items: stockSymbolNames.map((symbol) {
                      return DropdownMenuItem(
                        value: symbol,
                        child: Text(symbol),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStockName = value.toString();
                        selectedStockInfo =
                            getSelectedStockInfo(selectedStockName);
                        editedPrice = investments.firstWhere(
                          (investment) =>
                              investment['Stock Name'] == selectedStockName,
                          orElse: () => {},
                        )['Price'];
                        editedAmount = investments.firstWhere(
                          (investment) =>
                              investment['Stock Name'] == selectedStockName,
                          orElse: () => {},
                        )['Amount'];
                        editedDatePurchased = investments.firstWhere(
                          (investment) =>
                              investment['Stock Name'] == selectedStockName,
                          orElse: () => {},
                        )['Date Purchased'];
                      });
                    },
                  ),
                  if (selectedStockName.isNotEmpty) SizedBox(height: 20),
                  if (selectedStockInfo.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Stock Information: $selectedStockName'),
                        Text(selectedStockInfo),
                        FormBuilderTextField(
                          name: 'editedPrice',
                          decoration: InputDecoration(labelText: 'Edit Price'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            editedPrice = value!;
                          },
                        ),
                        FormBuilderTextField(
                          name: 'editedAmount',
                          decoration: InputDecoration(labelText: 'Edit Amount'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            editedAmount = value!;
                          },
                        ),
                        FormBuilderTextField(
                          name: 'editedDatePurchased',
                          decoration:
                              InputDecoration(labelText: 'Edit Date Purchased'),
                          onChanged: (value) {
                            editedDatePurchased = value!;
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                updateDataTable(selectedStockName, editedPrice,
                                    editedAmount, editedDatePurchased);
                              },
                              child: Text('Save'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (showCurrentPrice)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Price: $currentStockPrice'),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      await fetchStockData(selectedStockSymbol);
                      setState(() {
                        showCurrentPrice = true;
                        editedPrice = currentStockPrice;
                      });
                    },
                    child: Text('Get Current Price'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Price History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await fetchHistoricalStockData(
                              selectedStockSymbol, '1min');
                          setState(() {
                            selectedInterval = '1min';
                          });
                        },
                        child: Text('1 Week'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await fetchHistoricalStockData(
                              selectedStockSymbol, '15min');
                          setState(() {
                            selectedInterval = '15min';
                          });
                        },
                        child: Text('1 Quarter'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await fetchHistoricalStockData(
                              selectedStockSymbol, '60min');
                          setState(() {
                            selectedInterval = '60min';
                          });
                        },
                        child: Text('1 Year'),
                      ),
                    ],
                  ),
                  if (historicalPrice.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historical Price: $historicalPrice'),
                        Text('Percent Change: $percentChange'),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showGenerateGraphDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Generate Graph'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      togglePieChart();
                      generatePieChartData();
                    },
                    child: Text('Pie Chart'),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle Bar Chart button press
                    },
                    child: Text('Bar Chart'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String getSelectedStockInfo(String stockName) {
    final selectedStock = investments.firstWhere(
      (investment) => investment['Stock Name'] == stockName,
      orElse: () => {},
    );

    if (selectedStock != null) {
      final stockInfo = '''
        Date Purchased: ${selectedStock['Date Purchased']}
        Price: ${selectedStock['Price']}
        Amount: ${selectedStock['Amount']}
      ''';

      return stockInfo;
    } else {
      return 'Stock information not found';
    }
  }

  void updateDataTable(
      String stockName, String price, String amount, String datePurchased) {
    final index = investments
        .indexWhere((investment) => investment['Stock Name'] == stockName);

    if (index != -1) {
      setState(() {
        investments[index]['Price'] = price;
        investments[index]['Amount'] = amount;
        investments[index]['Date Purchased'] = datePurchased;
        editedPrice = '';
        editedAmount = '';
        editedDatePurchased = '';
      });
      Navigator.of(context).pop();
    }
  }

  final List<Map<String, String>> stocks = [
    // You can add more stock symbols here
    {'1. symbol': 'AAPL'},
    {'1. symbol': 'GOOGL'},
    {'1. symbol': 'MSFT'},
    {'1. symbol': 'AMZN'},
    {'1. symbol': 'NVDA'},
    {'1. symbol': 'BRKB'},
    {'1. symbol': 'TSLA'},
    {'1. symbol': 'META'},
    {'1. symbol': 'LLY'},
    {'1. symbol': 'V'}, //10
    {'1. symbol': 'UNH'},
    {'1. symbol': 'XOM'},
    {'1. symbol': 'TSM'},
    {'1. symbol': 'WMT'},
    {'1. symbol': 'JPM'},
    {'1. symbol': 'JNJ'},
    {'1. symbol': 'MA'},
    {'1. symbol': 'LVMUY'},
    {'1. symbol': 'TCEHY'},
    {'1. symbol': 'PG'}, // 20
    {'1. symbol': 'AVGO'},
    {'1. symbol': 'CVX'},
    {'1. symbol': 'HD'},
    {'1. symbol': 'NSRGY'},
    {'1. symbol': 'ORCL'},
    {'1. symbol': 'ABBV'},
    {'1. symbol': 'MRK'},
    {'1. symbol': 'TM'},
    {'1. symbol': 'COST'},
    {'1. symbol': 'KO'}, //30
    {'1. symbol': 'PEP'},
    {'1. symbol': 'ADBE'},
    {'1. symbol': 'ASML'},
    {'1. symbol': 'BAC'},
    {'1. symbol': 'CSCO'},
    {'1. symbol': 'SHEL'},
    {'1. symbol': 'AZN'},
    {'1. symbol': 'ACN'},
    {'1. symbol': 'NVS'},
    {'1. symbol': 'BABA'}, //40
    {'1. symbol': 'CRM'},
    {'1. symbol': 'MCD'},
    {'1. symbol': 'TMO'},
    {'1. symbol': 'PROSY'},
    {'1. symbol': 'RHHBY'},
    {'1. symbol': 'PFE'},
    {'1. symbol': 'DHR'},
    {'1. symbol': 'CMCSA'},
    {'1. symbol': 'LIN'},
    {'1. symbol': 'NFLX'}, //50
  ];

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
                      showAddInvestmentsDialog(context);
                    },
                    child: Text('Add Investments'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showMoreInformationDialog(context);
                    },
                    child: Text('More Information'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showGenerateGraphDialog(context);
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
              if (showPieChart)
                PieChart(
                  dataMap: pieChartData,
                  chartRadius: MediaQuery.of(context).size.width / 2,
                  chartType: ChartType.ring,
                  chartValuesOptions: ChartValuesOptions(
                    showChartValueBackground: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
