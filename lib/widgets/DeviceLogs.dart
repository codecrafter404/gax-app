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
  static List<DeviceLogEntry> fromBinary(List<int> data) {
    List<List<int>> chunks = [];
    for (var i = 0; i < data.length; i += 15) {
      chunks.add(data.sublist(i, i + 15));
    }
    final List<DeviceLogEntry> entries = chunks.map((x) {
      final List<int> time = x.sublist(0, 8);
      int timesum = x[0] << (64 - (8 * 1));
      timesum += x[1] << (64 - (8 * 2));
      timesum += x[2] << (64 - (8 * 3));
      timesum += x[3] << (64 - (8 * 4));
      timesum += x[4] << (64 - (8 * 5));
      timesum += x[5] << (64 - (8 * 6));
      timesum += x[6] << (64 - (8 * 7));
      timesum += x[7];

      final String mac =
          x.sublist(8, 14).map((x) => x.toRadixString(16)).join(":");
      final int? code = x[14] == 0 ? null : x[14];
      final DeviceLogEntryStatus status = code == null
          ? DeviceLogEntryStatus.success
          : DeviceLogEntryStatus.failure;
      return DeviceLogEntry(
        mac: mac,
        time: DateTime.now().subtract(Duration(seconds: timesum)),
        status: status,
        errorCode: code,
      );
    }).toList();
    return entries;
  }

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
