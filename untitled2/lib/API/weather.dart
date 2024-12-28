class Weather {
  final String cityName;
  final String region;
  final String country;
  final double feelsLikeC;
  final double temperatureC;
  final double windSpeedKph;
  final int humidity;
  final String conditionText; // Mô tả thời tiết
  final String conditionIconUrl; // URL biểu tượng thời tiết

  Weather({
    required this.cityName,
    required this.region,
    required this.country,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.windSpeedKph,
    required this.humidity,
    required this.conditionText,
    required this.conditionIconUrl,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      return Weather(
        cityName: json['location']?['name'] ?? 'Không xác định',
        region: json['location']?['region'] ?? 'Không xác định',
        country: json['location']?['country'] ?? 'Không xác định',
        temperatureC: json['current']?['temp_c']?.toDouble() ?? 0.0,
        feelsLikeC: json['current']?['feelslike_c']?.toDouble() ?? 0.0,
        windSpeedKph: json['current']?['wind_kph']?.toDouble() ?? 0.0,
        humidity: json['current']?['humidity'] ?? 0,
        conditionText: json['current']?['condition']?['text'] ?? 'Không có mô tả',
        conditionIconUrl: _constructIconUrl(json['current']?['condition']?['icon']),
      );
    } catch (e) {
      print("Lỗi khi đọc JSON: $e");
      return Weather(
        cityName: 'Không xác định',
        region: 'Không xác định',
        country: 'Không xác định',
        temperatureC: 0.0,
        feelsLikeC: 0.0,
        windSpeedKph: 0.0,
        humidity: 0,
        conditionText: 'Không có mô tả',
        conditionIconUrl: '',
      );
    }
  }

  static String _constructIconUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) {
      return '';
    }
    return 'https:$iconPath'; // Thêm tiền tố https vào đường dẫn biểu tượng
  }
}
