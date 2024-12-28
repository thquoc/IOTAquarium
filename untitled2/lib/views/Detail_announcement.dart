import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Util/Rangemanage.dart';

class DetailAnnouncement extends StatefulWidget {
  @override
  _DetailAnnouncementState createState() => _DetailAnnouncementState();
}

class _DetailAnnouncementState extends State<DetailAnnouncement> {
  final databaseReference = FirebaseDatabase.instance.ref();
  List<String> alerts = [];
  DateTime? lastAlertTime; // Thời gian gửi cảnh báo lần cuối

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
    _getSavedAlerts();
    _getRealtimeData();

    TempThreshold = RangeManage('Threshold/Temperature');
    pHThreshold = RangeManage('Threshold/pH');
    TurbidityThreshold = RangeManage('Threshold/Turbidity');
    DOThreshold = RangeManage('Threshold/DO');
    waterlevelThreshold = RangeManage('Threshold/Water Level');

    _registerThresholdCallbacks();
    _listenToFirebase();
  }

  void _registerThresholdCallbacks() {
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
  }

  void _listenToFirebase() {
    TempThreshold.listenToFirebase();
    pHThreshold.listenToFirebase();
    TurbidityThreshold.listenToFirebase();
    DOThreshold.listenToFirebase();
    waterlevelThreshold.listenToFirebase();
  }

  void _getSavedAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      alerts = prefs.getStringList('alerts') ?? [];
    });
    print("Alerts saved: ${alerts.length} items");
  }

  void _saveAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (alerts.length > 20) {
      await prefs.remove('alerts');
      print("Removed all saved alerts because there are more than 20.");
    } else {
      await prefs.setStringList('alerts', alerts);
    }
    print("Saved Alerts: ${alerts.length} items");
  }

  void _getRealtimeData() {
    databaseReference.child('datarealtime').onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;

        double DO = data['DO']?.toDouble() ?? 0;
        double temperature = data['Temperature']?.toDouble() ?? 0;
        double turbidity = data['Turbidity']?.toDouble() ?? 0;
        double waterLevel = data['WaterLevel']?.toDouble() ?? 0;
        double pH = data['pH']?.toDouble() ?? 0;

        String alertMessage = '';
        DateTime now = DateTime.now();
        String formattedDate =
            '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}';

        // Kiểm tra các điều kiện cảnh báo
        if ((DO < (DOMin ?? 0) || DO > (DOMax ?? 14.0)) && (DOMin != null || DOMax != null)) {
          alertMessage += 'Dissolved Oxygen: $DOMin <= $DO <= $DOMax\n';
        }
        if ((temperature < (TempMin ?? 24) || temperature > (TempMax ?? 28)) && (TempMin != null || TempMax != null)) {
          alertMessage += 'Temperature: $TempMin <= $temperature <= $TempMax\n';
        }
        if ((turbidity < (TurbidityMin ?? 5.0) || turbidity > (TurbidityMax ?? 30.0)) && (TurbidityMin != null || TurbidityMax != null)) {
          alertMessage += 'Turbidity: $TurbidityMin <= $turbidity <= $TurbidityMax\n';
        }
        if ((waterLevel < (waterlevelMin ?? 10.0) || waterLevel > (waterlevelMax ?? 15.0)) && (waterlevelMin != null || waterlevelMax != null)) {
          alertMessage += 'Water Level: $waterlevelMin <= $waterLevel <= $waterlevelMax\n';
        }
        if ((pH < (pHMin ?? 6.5) || pH > (pHMax ?? 8.5)) && (pHMin != null || pHMax != null)) {
          alertMessage += 'pH: $pHMin <= $pH <= $pHMax\n';
        }

        // Nếu có cảnh báo, cập nhật giao diện và gửi email
        if (alertMessage.isNotEmpty) {
          if (lastAlertTime == null || now.difference(lastAlertTime!).inMinutes >= 5) {
            String fullAlertMessage = 'Alert on $formattedDate: \n$alertMessage';
            setState(() {
              alerts.insert(0, fullAlertMessage);
              if (alerts.length > 20) {
                alerts.removeLast();
              }
            });
            _saveAlerts();
            FlutterRingtonePlayer.playRingtone();
            _sendEmailAlert(fullAlertMessage);
            lastAlertTime = now; // Cập nhật thời gian gửi cảnh báo
          }
        }
      }
    });
  }

  void _sendEmailAlert(String message) async {
    String username = 'nguyenquoc.qn1810@gmail.com'; // Thay đổi với email của bạn
    String password = 'enji iaqw xuht jcks'; // Thay đổi với mật khẩu ứng dụng Gmail

    final smtpServer = gmail(username, password);

    final emailMessage = Message()
      ..from = Address(username, 'Alert System')
      ..recipients.add('nguyenthanhquoc0206@gmail.com') // Thay đổi với email nhận
      ..subject = 'Alert Notification'
      ..text = message;

    try {
      final sendReport = await send(emailMessage, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF80DEEA), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Detail Alerts:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      String alert = alerts[index];

                      // Phân tích nội dung để làm nổi bật giá trị giữa "<=" và "<="
                      List<TextSpan> spans = [];
                      RegExp regExp = RegExp(r'(<=.*?<=)');
                      int lastIndex = 0;

                      Iterable<Match> matches = regExp.allMatches(alert);
                      for (var match in matches) {
                        if (lastIndex < match.start) {
                          spans.add(TextSpan(
                            text: alert.substring(lastIndex, match.start),
                            style: TextStyle(color: Colors.black),
                          ));
                        }

                        spans.add(TextSpan(
                          text: alert.substring(match.start, match.start + 2),
                          style: TextStyle(color: Colors.black),
                        ));

                        spans.add(TextSpan(
                          text: alert.substring(match.start + 2, match.end - 2),
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ));

                        spans.add(TextSpan(
                          text: alert.substring(match.end - 2, match.end),
                          style: TextStyle(color: Colors.black),
                        ));

                        lastIndex = match.end;
                      }

                      if (lastIndex < alert.length) {
                        spans.add(TextSpan(
                          text: alert.substring(lastIndex),
                          style: TextStyle(color: Colors.black),
                        ));
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: RichText(
                            text: TextSpan(
                              children: spans,
                            ),
                          ),
                        ),
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