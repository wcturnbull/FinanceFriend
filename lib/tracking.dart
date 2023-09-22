import 'package:flutter/material.dart';
import 'main.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.title});

  final String title;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
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
          ],)
      ),
    );
  }
}