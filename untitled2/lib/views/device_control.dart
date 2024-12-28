import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Util/device.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DeviceController(),
    );
  }
}

class DeviceController extends StatefulWidget {
  @override
  _DeviceControllerState createState() => _DeviceControllerState();
}

class _DeviceControllerState extends State<DeviceController> {
  bool isAutomaticMode = false;

  final List<Device> devices = [
    Device(name: 'Fan', icon: Icons.air, status: 'Inactive', statusColor: Colors.red, mode: 'Manual'),
    Device(name: 'LightingSys', icon: Icons.lightbulb, status: 'Inactive', statusColor: Colors.red, mode: 'Manual'),
    Device(name: 'AirPump', icon: Icons.bubble_chart, status: 'Inactive', statusColor: Colors.red, mode: 'Manual'),
    Device(name: 'FilterSystem', icon: Icons.filter_alt, status: 'Inactive', statusColor: Colors.red, mode: 'Manual'),
    Device(name: 'WaterPump', icon: Icons.water, status: 'Inactive', statusColor: Colors.red, mode: 'Manual'),
  ];

  late DatabaseReference _deviceRef;

  @override
  void initState() {
    super.initState();
    _deviceRef = FirebaseDatabase.instance.ref("State");

    // Lắng nghe thay đổi từ Firebase
    _deviceRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        // Lấy trạng thái chế độ từ Firebase
        isAutomaticMode = data['Mode'] == 1;  // Nếu Mode = "1" => Chế độ tự động

        // Cập nhật trạng thái thiết bị từ Firebase
        for (var device in devices) {
          device.status = data[device.name] == 1 ? 'Active' : 'Inactive';
          device.statusColor = device.status == 'Active' ? Colors.green : Colors.red;
        }
      });
    });
  }

  // Cập nhật trạng thái thiết bị lên Firebase
  void updateDeviceState(String deviceName, bool state) {
    _deviceRef.update({
      deviceName: state ? 1 : 0,  // "1" là bật, "0" là tắt
    });
  }

  // Cập nhật trạng thái chế độ
  void toggleMode(bool value) {
    setState(() {
      isAutomaticMode = value;
      _deviceRef.update({'Mode': isAutomaticMode ? 1 : 0});  // Chế độ tự động ("1" bật, "0" tắt)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Control'),
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
          // Các widget con nằm trên nền
          Column(
            children: [
              // Widget điều khiển chế độ (thủ công / tự động)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SwitchListTile(
                  title: Text('Automatic Mode'),
                  value: isAutomaticMode,
                  onChanged: toggleMode,
                  subtitle: Text(isAutomaticMode ? 'All devices are in Automatic Mode' : 'All devices are in Manual Mode'),
                ),
              ),
              // Danh sách các thiết bị
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return DeviceCard(device: device, updateDeviceState: updateDeviceState, isAutomaticMode: isAutomaticMode);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final Function(String, bool) updateDeviceState;
  final bool isAutomaticMode;

  DeviceCard({required this.device, required this.updateDeviceState, required this.isAutomaticMode});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(
                device: device,
                updateDeviceState: updateDeviceState,
                isAutomaticMode: isAutomaticMode,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(device.icon, size: 50, color: device.statusColor),
              Text(
                device.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                device.status,
                style: TextStyle(
                  fontSize: 16,
                  color: device.statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceDetailScreen extends StatelessWidget {
  final Device device;
  final Function(String, bool) updateDeviceState;
  final bool isAutomaticMode;

  DeviceDetailScreen({
    required this.device,
    required this.updateDeviceState,
    required this.isAutomaticMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                device.icon,
                size: 100,
                color: device.statusColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Device: ${device.name}",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              "Status: ${device.status}",
              style: TextStyle(fontSize: 20, color: device.statusColor),
            ),
            SizedBox(height: 10),
            Text(
              "Mode: ${device.mode}",
              style: TextStyle(fontSize: 20, color: Colors.blue),
            ),
            SizedBox(height: 20),
            // Chỉ hiển thị các nút khi chế độ là "Automatic Mode"
            if (!isAutomaticMode) ...[
              ElevatedButton(
                onPressed: () {
                  // Chuyển đổi trạng thái thiết bị
                  bool newState = device.status == 'Inactive';
                  updateDeviceState(device.name, newState);
                },
                child: Text(device.status == "Active" ? "Turn Off" : "Turn On"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}