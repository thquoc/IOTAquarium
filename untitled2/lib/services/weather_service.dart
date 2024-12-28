import 'dart:convert';
import 'package:http/http.dart' as http;
import '../API/weather.dart';

class WeatherService {
  final String apiKey = '594f963c643a4fcbaaa173730242011'; // Thay thế bằng API key của bạn

  Future<Weather> fetchWeather(String city) async {
    final response = await http.get(Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city'));

    if (response.statusCode == 200) {
      return Weather.fromJson(json.decode(response.body));
    } else {
      throw Exception('Không thể tải dữ liệu thời tiết');
    }
  }
}
