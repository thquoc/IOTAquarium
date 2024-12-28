import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CustomBarChart extends StatelessWidget {
  final List<double> temp;
  final List<double> pH;
  final List<double> turbidity;
  final List<double> doValues;
  final List<double> waterLevel;

  CustomBarChart({
    required this.temp,
    required this.pH,
    required this.turbidity,
    required this.doValues,
    required this.waterLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              _createBarChartData(),
              swapAnimationDuration: Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  BarChartData _createBarChartData() {
    return BarChartData(
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: _calculateAverage(temp),
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: _calculateAverage(pH),
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: _calculateAverage(turbidity),
              color: Colors.orange,
              width: 16,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        BarChartGroupData(
          x: 3,
          barRods: [
            BarChartRodData(
              toY: _calculateAverage(doValues),
              color: Colors.red,
              width: 16,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        BarChartGroupData(
          x: 4,
          barRods: [
            BarChartRodData(
              toY: _calculateAverage(waterLevel),
              color: Colors.purple,
              width: 16,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ],
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return Text("Temp", style: TextStyle(color: Colors.blue));
                case 1:
                  return Text("pH", style: TextStyle(color: Colors.green));
                case 2:
                  return Text("Turb", style: TextStyle(color: Colors.orange));
                case 3:
                  return Text("DO", style: TextStyle(color: Colors.red));
                case 4:
                  return Text("Water", style: TextStyle(color: Colors.purple));
                default:
                  return Text("");
              }
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
    );
  }

  double _calculateAverage(List<double> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.reduce((a, b) => a + b);
    return sum / data.length;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(Colors.blue, "Temperature"),
        _buildLegendItem(Colors.green, "pH"),
        _buildLegendItem(Colors.orange, "Turbidity"),
        _buildLegendItem(Colors.red, "DO"),
        _buildLegendItem(Colors.purple, "Water Level"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
