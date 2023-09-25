import 'package:flutter/material.dart';
import 'main.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.title});

  final String title;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController billTitleController = TextEditingController();
  final TextEditingController billDataController = TextEditingController();
  final TextEditingController billDateController = TextEditingController();

  void _navigateToHomePage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MyHomePage(title: widget.title),
    ));
  }

  List results = [];
  DataRow _getDataRow(index, data) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(data['title'])),
        DataCell(Text(data['note'])),
        DataCell(Text(data['duedate'])),
      ],
    );
  }

  Future fetchTracking() async {
    //database call
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: 
            IconButton(
              icon: Image.asset('ff_logo.png'),
              onPressed: () => _navigateToHomePage(context),
            ),
          title: Text('Bill Tracking Page'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bills'),
            FutureBuilder(
              future: fetchTracking(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  results = snapshot.data;
                  if (snapshot.data.length != 0) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.blue,
                        ),
                        columnSpacing: 30,
                        columns: [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Due Date')),
                        ],
                        rows: List.generate(
                          results.length,
                          (index) => _getDataRow(
                            index,
                            results[index],
                          ),
                        ),
                        showBottomBorder: true,
                      ),
                    );
                  } else {
                    return Row(
                      children: const <Widget>[
                        SizedBox(
                          child: CircularProgressIndicator(),
                          width: 30,
                          height: 30,
                        ),
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No Data Found...'),
                        ),
                      ],
                    );
                  }
                } else {
                  return Row(
                    children: const <Widget>[
                      SizedBox(
                        child: CircularProgressIndicator(),
                        width: 30,
                        height: 30,
                      ),
                      Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No Data Found...'),
                      ),
                    ],
                  );
                }
              },
            ),
            ElevatedButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Stack(
                      children: <Widget>[
                            Positioned(
                              right: -40,
                              top: -40,
                              child: InkResponse(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: const CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Please input bill data that you would like us to keep track of.', style: TextStyle(fontSize: 20))
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      Text('Bill Title: ', style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            hintText: 'Enter a title to identify the bill',
                                          ),
                                          controller: billTitleController,
                                        ),
                                      ),
                                    ],)
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      Text('Bill Data: ', style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            hintText: "Enter some data that you'd like to remember about the bill",
                                          ),
                                          controller: billDataController,
                                        ),
                                      ),
                                    ],)
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      Text('Bill Due Date: ', style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            hintText: 'Use MM/DD/YYYY',
                                          ),
                                          controller: billDateController,
                                        ),
                                      ),
                                    ],)
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ElevatedButton(
                                      child: const Text('Submit'),
                                      onPressed: () {
                                        String billTitle = billTitleController.text;
                                        String billData = billDataController.text;
                                        String billDate = billDateController.text;
                                        //send the data to database, refresh page if necessary
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                    )
                  )
                );
              },
              child: const Text('Open Popup'),
            )
          ],)
      ),
    );
  }
}