import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Util/Rangemanage.dart';

class MonthChart extends StatefulWidget {
  final List<double> temp;
  final List<double> pH;
  final List<double> turbidity;
  final List<double> doValues;
  final List<double> waterLevel;

  MonthChart({
    required this.temp,
    required this.pH,
    required this.turbidity,
    required this.doValues,
    required this.waterLevel,
  });

  @override
  _MonthChartState createState() => _MonthChartState();
}

class _MonthChartState extends State<MonthChart> {
  late RangeManage TempThreshold;
  late RangeManage pHThreshold;
  late RangeManage TurbidityThreshold;
  late RangeManage DOThreshold;
  late RangeManage waterlevelThreshold;

  double? TempMin, TempMax;
  double? pHMin, pHMax;
  double? TurbidityMin, TurbidityMax;
  double? DOMin, DOMax;
  double? waterlevelMin, waterlevelMax;

  @override
  void initState() {
    super.initState();

    // Khởi tạo RangeManage cho từng thông số
    TempThreshold = RangeManage('Threshold/Temperature');
    pHThreshold = RangeManage('Threshold/pH');
    TurbidityThreshold = RangeManage('Threshold/Turbidity');
    DOThreshold = RangeManage('Threshold/DO');
    waterlevelThreshold = RangeManage('Threshold/Water Level');

    // Lắng nghe thay đổi từ Firebase và cập nhật giao diện
    TempThreshold.onDataUpdated = (min, max) {
      setState(() {
        TempMin = min;
        TempMax = max;
      });
    };
    pHThreshold.onDataUpdated = (min, max) {
      setState(() {
        pHMin = min;
        pHMax = max;
      });
    };
    TurbidityThreshold.onDataUpdated = (min, max) {
      setState(() {
        TurbidityMin = min;
        TurbidityMax = max;
      });
    };
    DOThreshold.onDataUpdated = (min, max) {
      setState(() {
        DOMin = min;
        DOMax = max;
      });
    };
    waterlevelThreshold.onDataUpdated = (min, max) {
      setState(() {
        waterlevelMin = min;
        waterlevelMax = max;
      });
    };

    // Bắt đầu lắng nghe dữ liệu từ Firebase
    TempThreshold.listenToFirebase();
    pHThreshold.listenToFirebase();
    TurbidityThreshold.listenToFirebase();
    DOThreshold.listenToFirebase();
    waterlevelThreshold.listenToFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildTemperatureChart(),
            _buildPHChart(),
            _buildTurbidityChart(),
            _buildDOChart(),
            _buildWaterLevelChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    List<FlSpot> temperatureData = _createFlSpotData(widget.temp);
    return _buildChartWidget(temperatureData, Colors.blue,
        "Temperature", 0, 50, TempMin ?? 0, TempMax ?? 50);
  }

  Widget _buildPHChart() {
    List<FlSpot> phData = _createFlSpotData(widget.pH);
    return _buildChartWidget(phData, Colors.lime,
        "pH", 0, 14, pHMin ?? 0, pHMax ?? 14);
  }

  Widget _buildTurbidityChart() {
    List<FlSpot> turbidityData = _createFlSpotData(widget.turbidity);
    return _buildChartWidget(turbidityData, Colors.orange,
        "Turbidity", 0, 3000, TurbidityMin ?? 0, TurbidityMax ?? 3000);
  }

  Widget _buildDOChart() {
    List<FlSpot> doData = _createFlSpotData(widget.doValues);
    return _buildChartWidget(doData, Colors.yellow,
        "DO", 0, 14, DOMin ?? 0, DOMax ?? 14);
  }

  Widget _buildWaterLevelChart() {
    List<FlSpot> waterLevelData = _createFlSpotData(widget.waterLevel);
    return _buildChartWidget(waterLevelData, Colors.purple,
        "Water Level", 0, 300, waterlevelMin ?? 0, waterlevelMax ?? 300);
  }

  List<FlSpot> _createFlSpotData(List<double> data) {
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index]);
    });
  }

  Widget _buildChartWidget(List<FlSpot> data, Color color,
      String title, double minY, double maxY,
      double Threshold_min, double Threshold_max) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          _buildLineChart(data, color, minY, maxY, Threshold_min, Threshold_max),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> data, Color color, double minY, double maxY,
      double Threshold_min, double Threshold_max) {
    return Container(
      height: 300,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Container(),
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: color,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: Threshold_max,
                color: Colors.red,
                strokeWidth: 2,
                dashArray: [10, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => 'Upper limit',
                  alignment: Alignment.centerRight,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              HorizontalLine(
                y: Threshold_min,
                color: Colors.green,
                strokeWidth: 2,
                dashArray: [10, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => 'Under limit',
                  alignment: Alignment.centerRight,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
