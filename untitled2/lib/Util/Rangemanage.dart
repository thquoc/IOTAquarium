import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';


class RangeManage {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String documentId;
  double _min = 0;
  double _max = 0;

  // Callback để cập nhật dữ liệu từ Firebase
  Function(double min, double max)? onDataUpdated;

  RangeManage(this.documentId);

  // Getter
  double get min => _min;
  double get max => _max;

  // Setter
  set min(double value) {
    _min = value;
  }

  set max(double value) {
    _max = value;
  }

  void listenToFirebase() {
    final ref = _database.child(documentId);

    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        // Ép kiểu dữ liệu từ Firebase sang double
        _min = _safeCastToDouble(data['min']);
        _max = _safeCastToDouble(data['max']);

        // Nếu có thay đổi dữ liệu, gọi callback
        if (onDataUpdated != null) {
          onDataUpdated!(_min, _max);
        }
      }
    });
  }

// Hàm giúp ép kiểu an toàn
  double _safeCastToDouble(dynamic value) {

    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return 0.0; // Giá trị mặc định nếu không thể ép kiểu
    }
  }

}
