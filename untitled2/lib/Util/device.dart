import 'package:flutter/material.dart';


class Device {
  final String name;
  final IconData icon;
  String status; // Trạng thái có thể thay đổi
  //final String details;
  Color statusColor;
  DateTime? activeSince; // Thêm thời gian hoạt động
  String? mode;

  Device({
    required this.name,
    required this.icon,
    required this.status,
    //required this.details,
    required this.statusColor,
    this.activeSince,
    this.mode,
  });
}
