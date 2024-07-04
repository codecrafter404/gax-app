import 'package:flutter/material.dart';

class DeviceLogEntry {
  final String mac;
  final DateTime time;
  final DeviceLogEntryStatus status;
  final int? errorCode;

  DeviceLogEntry(
      {required this.mac,
      required this.time,
      required this.status,
      required this.errorCode});
  factory DeviceLogEntry.fromJson(Map<String, dynamic> data) {
    final String mac = (data['mac'] as String).toUpperCase();
    final DateTime time = DateTime.now().subtract(
      Duration(
        milliseconds: (data['time'] as int),
      ),
    );
    late DeviceLogEntryStatus status;
    int? errorCode;
    if (data['status'] is Map<String, dynamic>) {
      status = DeviceLogEntryStatus.failure;
      errorCode = (data['status'] as Map<String, dynamic>)['Failed'] as int;
    } else {
      status = (data['status'] as String) == "Successful"
          ? DeviceLogEntryStatus.success
          : DeviceLogEntryStatus.failure;
    }

    return DeviceLogEntry(
      errorCode: errorCode,
      mac: mac,
      status: status,
      time: time,
    );
  }
}

enum DeviceLogEntryStatus {
  success,
  failure,
}

class DeviceLogs extends StatelessWidget {
  const DeviceLogs({super.key, required this.logs});

  final List<DeviceLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    logs.sort((a, b) => a.time.compareTo(b.time));

    return logs.isNotEmpty
        ? ListView(
            children: logs.map((a) => buildListTile(a)).toList(),
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list),
                Text("Currently, there're no logs"),
              ],
            ),
          );
  }

  ListTile buildListTile(DeviceLogEntry entry) {
    return ListTile(
      title: Text(entry.time.toIso8601String()),
      subtitle: Text(entry.mac.toUpperCase()),
      leading: const CircleAvatar(
        child: Icon(Icons.check_sharp),
      ),
    );
  }
}
