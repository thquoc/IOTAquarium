import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert'; // Để xử lý JSON
import 'package:shared_preferences/shared_preferences.dart';

class _ChartData {
  final double x; // Thời gian
  final double y; // Giá trị cảm biến

  _ChartData(this.x, this.y);
}

class RealtimeDataScreen extends StatefulWidget {
  @override
  _RealtimeDataScreenState createState() => _RealtimeDataScreenState();
}

class _RealtimeDataScreenState extends State<RealtimeDataScreen> {
  List<_ChartData> temperatureData = [];
  List<_ChartData> phData = [];
  List<_ChartData> turbidityData = [];
  List<_ChartData> doData = [];
  List<_ChartData> waterLevelData = [];

  final databaseReference = FirebaseDatabase.instance.ref();

  double? tempMin, tempMax;
  double? phMin, phMax;
  double? turbidityMin, turbidityMax;
  double? doMin, doMax;
  double? waterLevelMin, waterLevelMax;

  ChartSeriesController? _chartSeriesController;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadChartData(); // Tải dữ liệu đã lưu
    _getRealtimeData();
    _listenToThresholdValues();
  }

  Future<void> _saveChartData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperatureData', jsonEncode(temperatureData.map((e) => {'x': e.x, 'y': e.y}).toList()));
    await prefs.setString('phData', jsonEncode(phData.map((e) => {'x': e.x, 'y': e.y}).toList()));
    await prefs.setString('turbidityData', jsonEncode(turbidityData.map((e) => {'x': e.x, 'y': e.y}).toList()));
    await prefs.setString('doData', jsonEncode(doData.map((e) => {'x': e.x, 'y': e.y}).toList()));
    await prefs.setString('waterLevelData', jsonEncode(waterLevelData.map((e) => {'x': e.x, 'y': e.y}).toList()));
  }

  Future<void> _loadChartData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      temperatureData = _loadDataList(prefs.getString('temperatureData'));
      phData = _loadDataList(prefs.getString('phData'));
      turbidityData = _loadDataList(prefs.getString('turbidityData'));
      doData = _loadDataList(prefs.getString('doData'));
      waterLevelData = _loadDataList(prefs.getString('waterLevelData'));
    });
  }

  List<_ChartData> _loadDataList(String? jsonData) {
    if (jsonData == null) return [];
    List<dynamic> dataList = jsonDecode(jsonData);
    return dataList.map((e) => _ChartData(e['x'], e['y'])).toList();
  }

  void _getRealtimeData() {
    databaseReference.child('datarealtime').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

        setState(() {
          temperatureData.add(_ChartData(currentTime, data['Temperature'].toDouble()));
          phData.add(_ChartData(currentTime, data['pH'].toDouble()));
          turbidityData.add(_ChartData(currentTime, data['Turbidity'].toDouble()));
          doData.add(_ChartData(currentTime, data['DO'].toDouble()));
          waterLevelData.add(_ChartData(currentTime, data['WaterLevel'].toDouble()));

          if (temperatureData.length > 100) {
            temperatureData.removeAt(0);
            phData.removeAt(0);
            turbidityData.removeAt(0);
            doData.removeAt(0);
            waterLevelData.removeAt(0);
          }
        });

        _saveChartData(); // Lưu dữ liệu biểu đồ
      }
    });
  }

  void _listenToThresholdValues() {
    databaseReference.child('Threshold/Temperature').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          tempMin = data['min']?.toDouble();
          tempMax = data['max']?.toDouble();
        });
      }
    });

    databaseReference.child('Threshold/pH').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          phMin = data['min']?.toDouble();
          phMax = data['max']?.toDouble();
        });
      }
    });

    databaseReference.child('Threshold/Turbidity').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          turbidityMin = data['min']?.toDouble();
          turbidityMax = data['max']?.toDouble();
        });
      }
    });

    databaseReference.child('Threshold/DO').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          doMin = data['min']?.toDouble();
          doMax = data['max']?.toDouble();
        });
      }
    });

    databaseReference.child('Threshold/Water Level').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          waterLevelMin = data['min']?.toDouble();
          waterLevelMax = data['max']?.toDouble();
        });
      }
    });
  }

  Widget _buildChartWidget(
      String title, List<_ChartData> data, double minY, double maxY, double? thresholdMin, double? thresholdMax) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    series: <LineSeries<_ChartData, double>>[
                      LineSeries<_ChartData, double>(
                        onRendererCreated: (ChartSeriesController controller) {
                          _chartSeriesController = controller;
                        },
                        dataSource: data,
                        xValueMapper: (_ChartData data, _) => data.x,
                        yValueMapper: (_ChartData data, _) => data.y,
                        color: Colors.blue,
                        width: 2,
                      ),
                    ],
                    primaryXAxis: NumericAxis(isVisible: false),
                    primaryYAxis: NumericAxis(
                      minimum: minY,
                      maximum: maxY,
                      plotBands: <PlotBand>[
                        if (thresholdMin != null)
                          PlotBand(
                            start: thresholdMin,
                            end: thresholdMin,
                            borderColor: Colors.green,
                            borderWidth: 2,
                            dashArray: <double>[10, 5],
                          ),
                        if (thresholdMax != null)
                          PlotBand(
                            start: thresholdMax,
                            end: thresholdMax,
                            borderColor: Colors.red,
                            borderWidth: 2,
                            dashArray: <double>[10, 5],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green[50],
        child: ListView(
          children: [
            _buildChartWidget('Temperature', temperatureData, 0, 50, tempMin, tempMax),
            _buildChartWidget('pH', phData, 0, 14, phMin, phMax),
            _buildChartWidget('Turbidity', turbidityData, 0, 3000, turbidityMin, turbidityMax),
            _buildChartWidget('DO (Dissolved Oxygen)', doData, 0, 14, doMin, doMax),
            _buildChartWidget('Water Level', waterLevelData, 0, 300, waterLevelMin, waterLevelMax),
          ],
        ),
      ),
    );
  }
}
