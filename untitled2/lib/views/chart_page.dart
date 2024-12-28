import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../views/RealtimeChart.dart';
import 'monthchart.dart';
 import '../views/barChart.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<double> temp = [];
  List<double> pH = [];
  List<double> turbidity = [];
  List<double> doValues = [];
  List<double> waterLevel = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref("data/2024-11");

    ref.once().then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        Map<String, List<Map<String, dynamic>>> groupedData = {};

        data.forEach((date, values) {
          String day = date.substring(0, 2);
          if (!groupedData.containsKey(day)) {
            groupedData[day] = [];
          }
          if (values is Map) {
            groupedData[day]?.add(Map<String, dynamic>.from(values));
          }
        });

        groupedData.forEach((day, valuesList) {
          double tempSum = 0, pHSum = 0, turbiditySum = 0, doSum = 0, waterLevelSum = 0;
          for (var values in valuesList) {
            tempSum += _convertToDouble(values['Temperature']);
            pHSum += _convertToDouble(values['pH']);
            turbiditySum += _convertToDouble(values['Turbidity']);
            doSum += _convertToDouble(values['DO']);
            waterLevelSum += _convertToDouble(values['WaterLevel']);
          }

          int count = valuesList.length;
          temp.add(_roundToOneDecimal(tempSum / count));
          pH.add(_roundToOneDecimal(pHSum / count));
          turbidity.add(_roundToOneDecimal(turbiditySum / count));
          doValues.add(_roundToOneDecimal(doSum / count));
          waterLevel.add(_roundToOneDecimal(waterLevelSum / count));

          print("Day: $day");
          print("Average Temperature: ${temp.last}");
          print("Average pH: ${pH.last}");
          print("Average Turbidity: ${turbidity.last}");
          print("Average DO: ${doValues.last}");
          print("Average WaterLevel: ${waterLevel.last}");
        });

        setState(() {});
      } else {
        print("No data found");
      }
    }).catchError((error) {
      print("Error fetching data: $error");
    });
  }

  double _convertToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }

  double _roundToOneDecimal(double value) {
    return double.parse(value.toStringAsFixed(1));
  }



  double _calculateAverage(List<double> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.reduce((a, b) => a + b);
    return sum / data.length;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Đóng Drawer khi nhấp vào mục
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chart"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.lightBlue.shade100,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.bar_chart, color: Colors.blue),
                title: Text('Realtime Chart'),
                onTap: () => _onItemTapped(0),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.green),
                title: Text('Month Chart'),
                onTap: () => _onItemTapped(1),
              ),
              ListTile(
                leading: Icon(Icons.insert_chart, color: Colors.orange),
                title: Text('BarChart'),
                onTap: () => _onItemTapped(2),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:  Alignment.bottomCenter,
                colors: [Color(0xFF80DEEA), Color(0xFFFFFFFF)],
              )
            ),
          ),
          _selectedIndex == 0
              ? RealtimeDataScreen()
              : _selectedIndex == 1
              ? MonthChart(temp: temp, pH: pH, turbidity: turbidity, doValues: doValues, waterLevel: waterLevel)
              : CustomBarChart(temp: temp, pH: pH, turbidity: turbidity, doValues: doValues, waterLevel: waterLevel)
        ],
      )

    );
  }
}
