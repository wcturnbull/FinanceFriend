import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

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
  String selectedRecommendation1 = '';
  String selectedRecommendation2 = '';

  List<DataRow> investmentsTableRows = [];

  //Methods To Fetch And Display FireBase Data For the DataTable
  @override
  void initState() {
    super.initState();
    // Fetch data from Firebase when the page is initialized
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    final investmentsRef =
        reference.child('users/${currentUser?.uid}/investments');

    DataSnapshot investmentsData = await investmentsRef.get();

    if (investmentsData.exists) {
      Map<String, dynamic> investmentsMap =
          investmentsData.value as Map<String, dynamic>;
      final List<Map<String, dynamic>> firebaseInvestments = [];

      investmentsMap.forEach((key, value) {
        firebaseInvestments.add(Map<String, dynamic>.from(value));
      });

      setState(() {
        investments = firebaseInvestments;
      });
    } else {
      setState(() {
        investments = [
          // {
          //   'Stock Name': 'HIasdfl',
          //   'Date Purchased': '2023-10-01',
          //   'Amount': '10',
          //   'Price': '1500.00',
          // },
        ];
      });
    }
  }

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
      // Include both price and percent in the pie chart data
      pieChartData['${investment['Stock Name']} - \$${investment['Price']}'] =
          percentage;
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

  //Code For The Add Investments Button
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

                  double price = double.parse(formData['price']);
                  double amount = double.parse(formData['amount']);

                  // Create a Map for the new investment
                  final newInvestment = {
                    'Stock Name': formData['stockOption'],
                    'Date Purchased': currentDate,
                    'Amount': amount.toString(),
                    'Price': (price * amount).toStringAsFixed(2),
                  };

                  // Add the new investment to the local list (for UI)
                  setState(() {
                    investments.add(newInvestment);
                  });

                  // Save the new investment to Firebase
                  reference
                      .child('users/${currentUser?.uid}/investments')
                      .push()
                      .set(newInvestment);

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

  //Method To Handle More Information Button Section
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

  //Method For Handling Graph Generation
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

  //Method For New Screen When You Click The Recommendations Button
  void showRecommendationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Recommendations'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderDropdown(
                    name: 'riskPreference',
                    decoration: InputDecoration(labelText: 'Risk Level'),
                    items: [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('High'),
                      ),
                      DropdownMenuItem(
                        value: 'noPreference',
                        child: Text('No Preference'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRecommendation1 = value!;
                      });
                    },
                  ),
                  FormBuilderDropdown(
                    name: 'assetPreference',
                    decoration: InputDecoration(labelText: 'Asset Preference'),
                    items: [
                      DropdownMenuItem(
                        value: 'stocks',
                        child: Text('Stocks'),
                      ),
                      DropdownMenuItem(
                        value: 'bonds',
                        child: Text('Bonds'),
                      ),
                      DropdownMenuItem(
                        value: 'pms',
                        child: Text('Precious Metals'),
                      ),
                      DropdownMenuItem(
                        value: 'noPreference',
                        child: Text('No Preference'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRecommendation2 = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    String advice = '';
                    if (selectedRecommendation1 == 'low') {
                      if (selectedRecommendation2 == 'stocks') {
                        advice =
                            'Recommendation: VOO - Vanguard S&P 500 ETF. This investment provides broad exposure to the top stocks of the NYSE with little cumulative risk.';
                      } else if (selectedRecommendation2 == 'bonds') {
                        advice =
                            'Recommendation: SHY - iShares 1-3 Years Treasury Bond ETF. This investment tracks a market weighted index of debt issued by the US Treasury with 1-3 years remaining to maturity.';
                      } else if (selectedRecommendation2 == 'pms') {
                        advice =
                            'Recommendation: GLD - SPDR Gold Trust. This investment tracks the gold spot price, less expenses and liabilities, using gold bars held in London vaults.';
                      } else if (selectedRecommendation2 == 'noPreference') {
                        advice =
                            'Recommendation: VEA - Vanguard FTSE Developed Markets ETF. This investment is passively managed to provide exposure to the developed markets ex-US equity space. It holds stocks of any market capitalization.';
                      }
                    } else if (selectedRecommendation1 == 'medium') {
                      if (selectedRecommendation2 == 'stocks') {
                        advice =
                            'Recommendation: IBM - International Business Machines Corp. IBM is an information technology company, which engages in the provision of integrated solutions that leverage information technology and knowledge of business processes';
                      } else if (selectedRecommendation2 == 'bonds') {
                        advice =
                            'Recommendation: VCIT - Vanguard Intermediate-Term Corporate Bond ETF. This investment tracks a market value-weighted index of US investment grade corporate bonds with maturities of 5-10 years.';
                      } else if (selectedRecommendation2 == 'pms') {
                        advice =
                            'Recommendation: SLV - iShares Silver Trust. This investment tracks the silver spot price, less expenses and liabilities, using silver bullion held in London.';
                      } else if (selectedRecommendation2 == 'noPreference') {
                        advice =
                            'Recommendation: CBT - Cabot Corp. Cabot Corp. is a global specialty chemicals and performance materials company. Its products are rubber and specialty grade carbon blacks, specialty compounds, fumed metal oxides, activated carbons, inkjet colorants, and aerogel.';
                      }
                    } else if (selectedRecommendation1 == 'high') {
                      if (selectedRecommendation2 == 'stocks') {
                        advice =
                            'Recommendation: CZR - Caesars Entertainment, Inc. Caesars Entertainment, Inc. engages in the management of casinos and resorts under the Caesars, Harrah\'s, Horseshoe, and Eldorado brands. It was founded in the Las Vegas area.';
                      } else if (selectedRecommendation2 == 'bonds') {
                        advice =
                            'Recommendation: BNDX - Vanguard Total International Bond ETF. This investment tracks an investment-grade, non-USD denominated bond index, hedged against currency fluctuations for US investors.';
                      } else if (selectedRecommendation2 == 'pms') {
                        advice =
                            'Recommendation: SPPP - Sprott Physical Platinum and Palladium Trust. SPPP is a closed-end trust that invests in unencumbered and fully-allocated Good Delivery physical platinum and palladium bullion.';
                      } else if (selectedRecommendation2 == 'noPreference') {
                        advice =
                            'Recommendation: BTC - BitCoin. Bitcoin is the first successful internet money based on peer-to-peer technology; whereby no central bank or authority is involved in the transaction and production of the Bitcoin currency.';
                      }
                    } else if (selectedRecommendation1 == 'noPreference') {
                      if (selectedRecommendation2 == 'stocks') {
                        advice =
                            'Recommendation: AMD - Advanced Micro Devices, Inc. Advanced Micro Devices, Inc. engages in the provision of semiconductor businesses. It operates through the following segments: Computing & Graphics, and Enterprise, Embedded and Semi-Custom. ';
                      } else if (selectedRecommendation2 == 'bonds') {
                        advice =
                            'Recommendation: MUB - iShares National Muni Bond ETF. This investment tracks a market-weighted index of investment-grade debt issued by state and local governments and agencies. Interest is exempt from US income tax and from AMT.';
                      } else if (selectedRecommendation2 == 'pms') {
                        advice =
                            'Recommendation: GOLD - Barrick Gold Corp. Barrick Gold Corp. engages in the production and sale of gold, copper, and related activities. It also provides exploration and mining development.';
                      } else if (selectedRecommendation2 == 'noPreference') {
                        advice =
                            'Recommendation: VNQ - Vanguard Real Estate ETF. This investment tracks a market-cap-weighted index of companies involved in the ownership and operation of real estate in the United States.';
                      }
                    }
                    // Display the advice underneath the DataTable
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(advice),
                        backgroundColor: Color.fromARGB(255, 59, 139, 61),
                        duration: Duration(seconds: 100),
                      ),
                    );
                    Navigator.of(context).pop();
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
            );
          },
        );
      },
    );
  }

  //Method To Handle The Compare Button's Click Events
  void showCompareDialog(BuildContext context) {
    final stockSymbolNames = investments.map((investment) {
      return investment['Stock Name'];
    }).toList();

    String selectedStockName = ''; // To store the selected stock name
    String originalPrice = '';
    String currentPrice = '';
    String percentChange = '5';
    String oldPrice = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Compare Dialog'),
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
                        originalPrice =
                            getSelectedStockPrice(selectedStockName);
                        oldPrice = getOldPrice(selectedStockName);
                      });
                    },
                  ),
                  if (selectedStockName
                      .isNotEmpty) // Display when a stock is selected
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await fetchHistoricalStockData(
                                selectedStockSymbol, '60min');
                            setState(() {
                              selectedInterval = '60min';
                              String cAmount = investments.firstWhere(
                                (investment) =>
                                    investment['Stock Name'] ==
                                    selectedStockName,
                                orElse: () => {'Amount': ''},
                              )['Amount'];
                              String newhistoricalPrice =
                                  (double.parse(historicalPrice) *
                                          double.parse(cAmount))
                                      .toStringAsFixed(2);
                              percentChange = calculatePercentChange(
                                  originalPrice, newhistoricalPrice);
                            });
                          },
                          child: Text('Compare'),
                        ),
                        if (historicalPrice.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Original Price: \$$originalPrice'),
                              Text(
                                  'Current Price: \$${(double.parse(historicalPrice) * double.parse(investments.firstWhere((investment) => investment['Stock Name'] == selectedStockName)['Amount'])).toStringAsFixed(2)}'),
                              Text(
                                'Percent Change: $percentChange%',
                                style: TextStyle(
                                  color: double.parse(percentChange) > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )
                            ],
                          ),
                      ],
                    ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // Update the color of the selected stock symbol based on percentChange
                    updateSelectedStockColor(percentChange, selectedStockName);
                    Navigator.of(context).pop();
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
            );
          },
        );
      },
    );
  }

  // Method to update the color of the selected stock symbol based on percentChange
  void updateSelectedStockColor(String percentChange, String stockName) {
    final selectedStock = investments.firstWhere(
      (investment) => investment['Stock Name'] == stockName,
    );

    if (selectedStock != null) {
      final double change = double.parse(percentChange);
      if (change > 0) {
        selectedStock['Color'] =
            Colors.green; // Change to green if percentChange is positive
      } else if (change < 0) {
        selectedStock['Color'] =
            Colors.red; // Change to red if percentChange is negative
      }
    }
  }

  String calculatePercentChange(String originalPrice, String currentPrice) {
    double original = double.parse(originalPrice);
    double current = double.parse(currentPrice);

    double change = current - original;
    double percentChange1 = (change / original * 100);

    return percentChange1.toStringAsFixed(2);
  }

//Helper Method For Compare Dialog Method
  String getSelectedStockPrice(String stockName) {
    final selectedStock = investments.firstWhere(
      (investment) => investment['Stock Name'] == stockName,
      orElse: () => {},
    );

    if (selectedStock != null) {
      return selectedStock['Price'];
    } else {
      return 'Stock information not found';
    }
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

  String getOldPrice(String stockSymbol) {
    final selectedStock = investments.firstWhere(
      (investment) => investment['Stock Name'] == stockSymbol,
    );

    if (selectedStock != null) {
      return selectedStock['Price'];
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
        investments[index]['Price'] =
            (double.parse(price) * double.parse(amount)).toStringAsFixed(2);
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
      appBar: FFAppBar(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showRecommendationsDialog(context);
                    },
                    child: Text('Recommendations'),
                  ),
                  SizedBox(
                      width: 16), // Add horizontal space between the buttons
                  ElevatedButton(
                    onPressed: () {
                      showCompareDialog(context);
                    },
                    child: Text('Compare'),
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
