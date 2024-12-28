import '../services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../API/weather.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final WeatherService weatherService = WeatherService();

  List<Map<String, dynamic>> sensors = [];
  Weather? weatherData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _listenToRealtimeSensorData();
  }

  Future<void> _fetchWeather() async {
    try {
      final data = await weatherService.fetchWeather("Da Nang");
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Không thể tải dữ liệu thời tiết. Vui lòng thử lại.";
      });
    }
  }

  void _listenToRealtimeSensorData() {
    final ref = _database.ref('datarealtime');

    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          sensors = [
            {'name': 'DO', 'value': (data['DO'] as num).toDouble()},
            {'name': 'Temperature', 'value': (data['Temperature'] as num).toDouble()},
            {'name': 'Turbidity', 'value': (data['Turbidity'] as num).toDouble()},
            {'name': 'Water Level', 'value': (data['WaterLevel'] as num).toDouble()},
            {'name': 'pH', 'value': (data['pH'] as num).toDouble()},
          ];
        });
      }
      _loadThresholds();
    }, onError: (error) {
      print("Lỗi khi theo dõi dữ liệu Firebase: $error");
    });
  }

  void _loadThresholds() {
    final thresholdsRef = _database.ref('Threshold');

    thresholdsRef.once().then((snapshot) {
      final thresholds = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (thresholds != null) {
        setState(() {
          for (var sensor in sensors) {
            final sensorName = sensor['name'];
            if (thresholds.containsKey(sensorName)) {
              final threshold = thresholds[sensorName];
              sensor['min'] = (threshold['min'] is num ? (threshold['min'] as num).toDouble() : 0.0);
              sensor['max'] = (threshold['max'] is num ? (threshold['max'] as num).toDouble() : 0.0);
            }
          }
        });
      }
    }).catchError((error) {
      print("Lỗi khi tải ngưỡng từ Firebase: $error");
    });
  }


  void _updateThreshold(String sensorName, double newMin, double newMax) {
    final ref = _database.ref('Threshold/$sensorName');
    ref.set({
      'min': newMin,
      'max': newMax,
    }).then((_) {
      print('Cập nhật ngưỡng thành công cho $sensorName');
    }).catchError((error) {
      print("Cập nhật ngưỡng thất bại: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text("Home Page"),
      ),
      body: Stack(
        children: [
          // Nền gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF80DEEA), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                      ? Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : WeatherWidget(weather: weatherData),
                ),
                Expanded(
                  child: sensors.isEmpty
                      ? const Center(child: Text("Không có dữ liệu cảm biến"))
                      : ListView.builder(
                    itemCount: sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = sensors[index];
                      return SensorCard(
                        name: sensor['name'],
                        value: sensor['value'],
                        min: sensor['min'] ?? 0.0,
                        max: sensor['max'] ?? 0.0,
                        onUpdateThreshold: (newMin, newMax) {
                          setState(() {
                            sensor['min'] = newMin;
                            sensor['max'] = newMax;
                          });
                          _updateThreshold(sensor['name'], newMin, newMax);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final Weather? weather;

  const WeatherWidget({required this.weather, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const Center(
        child: Text(
          'Không có dữ liệu thời tiết',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Thành phố: ${weather!.cityName}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: weather!.conditionIconUrl,
                  width: 60,
                  height: 60,
                  placeholder: (context, url) =>
                  const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error),
                ),
                const SizedBox(width: 10),
                Text(
                  "${weather!.conditionText}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildWeatherInfoRow(Icons.thermostat, "Nhiệt độ",
                "${weather!.temperatureC}°C"),
            _buildWeatherInfoRow(
                Icons.air, "Gió", "${weather!.windSpeedKph} km/h"),
            _buildWeatherInfoRow(Icons.water_drop, "Độ ẩm",
                "${weather!.humidity}%"),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 24),
        const SizedBox(width: 10),
        Text(
          "$label: $value",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  final String name;
  final double value;
  final double min;
  final double max;
  final Function(double, double) onUpdateThreshold;

  const SensorCard({
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    required this.onUpdateThreshold,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double dangerLevel = ((value - min) / (max - min)).clamp(0.0, 1.0);

    String emoji =(value < min || value > max )? '😡': dangerLevel> 0.75? '😨': '😊';

    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 70.0,
              lineWidth: 8.0,
              percent: dangerLevel,
              center: Text(
                emoji,
                style: const TextStyle(fontSize: 30),
              ),
              progressColor: dangerLevel > 0.75
                  ? const Color(0xFFE53935)
                  : (dangerLevel > 0.5
                  ? const Color(0xFFFB8C00)
                  : const Color(0xFF43A047)),
              backgroundColor: const Color(0xFFF5F5F5),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Giá trị: $value",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Text(
                  "Ngưỡng: $min-$max",
                  style: const TextStyle(fontSize: 16, color: Colors.black45),
                ),
                IconButton(
                  onPressed: () {
                    _showThresholdDialog(context, name, min, max);
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  iconSize: 20.0,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdDialog(
      BuildContext context, String sensorName, double min, double max) {
    final minController = TextEditingController(text: min.toString());
    final maxController = TextEditingController(text: max.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cập nhật ngưỡng"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Min"),
              ),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newMin = double.tryParse(minController.text) ?? min;
                final newMax = double.tryParse(maxController.text) ?? max;
                onUpdateThreshold(newMin, newMax);
                Navigator.pop(context);
              },
              child: const Text("Cập nhật"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
          ],
        );
      },
    );
  }
}
