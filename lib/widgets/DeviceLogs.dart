import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gax_app/pages/home.dart';

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
    logs.sort((a, b) => b.time.compareTo(a.time));

    return logs.isNotEmpty
        ? ListView(
            children: logs.map((a) => buildListTile(a, context)).toList(),
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

  ListTile buildListTile(DeviceLogEntry entry, BuildContext context) {
    return ListTile(
      title: Text(
          "${entry.time.day.toString().padLeft(2, '0')}.${entry.time.month.toString().padLeft(2, '0')}.${entry.time.year.toString().padLeft(4, '0')} ${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}"), // DD.MM.YYYY HH:mm:ss
      subtitle: Text(entry.mac.toUpperCase()),
      leading: CircleAvatar(
        child: entry.status == DeviceLogEntryStatus.success
            ? Icon(Icons.check_sharp)
            : Icon(Icons.error),
      ),
      onTap: () {
        if (entry.status == DeviceLogEntryStatus.failure) {
          String msg = getMessageToErrorCode(entry.errorCode!);
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Error Message:"),
                content: Text(msg),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: msg));
                    },
                    child: const Text("Copy"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, "");
                    },
                    child: const Text("Close"),
                  )
                ],
              );
            },
          );
        }
      },
    );
  }
}
