import 'package:flutter/material.dart';

class DeviceLogEntry {
  final String mac;
  final DateTime time;
  final DeviceLogEntryStatus status;

  DeviceLogEntry({required this.mac, required this.time, required this.status});
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
        : Center(
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
      leading: CircleAvatar(
        child: Icon(Icons.check_sharp),
      ),
    );
  }
}
