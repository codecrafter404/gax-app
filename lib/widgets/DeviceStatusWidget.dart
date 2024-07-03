import 'package:flutter/material.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';

class DeviceStatusWidget extends StatelessWidget {
  const DeviceStatusWidget({
    super.key,
    required this.deviceStatus,
  });

  final DeviceInformation deviceStatus;
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        buildTableRow(
          "Device connected:",
          deviceStatus.deviceConnected ? "true" : "false",
          deviceStatus.deviceConnected ? Colors.green : Colors.red,
        ),
        buildTableRow(
          "Power-On-Hours:",
          "${deviceStatus.powerOnHours.toString()}h",
          Theme.of(context).primaryColor,
        )
      ],
    );
  }

  TableRow buildTableRow(String name, String meta, Color metaColor) {
    return TableRow(
      children: [
        Text(name),
        Center(
          child: Text(
            meta,
            style: TextStyle(
              color: metaColor,
            ),
          ),
        ),
      ],
    );
  }
}

class DeviceInformation {
  String deviceName;
  bool deviceConnected;
  int powerOnHours;
  String mac;
  String serviceUUID;
  String challengeCharacteristicUUID;
  String privKey;
  List<DeviceLogEntry> logEntries;

  DeviceInformation(
      {required this.deviceName,
      required this.deviceConnected,
      required this.powerOnHours,
      required this.mac,
      required this.privKey,
      required this.logEntries,
      required this.serviceUUID,
      required this.challengeCharacteristicUUID});
  factory DeviceInformation.fromEssentials(String mac, String serviceUUID,
      String challengeCharacteristicUUID, String privKey, String name) {
    return DeviceInformation(
        deviceConnected: false,
        deviceName: name,
        mac: mac,
        privKey: privKey,
        powerOnHours: -1,
        logEntries: [],
        serviceUUID: serviceUUID,
        challengeCharacteristicUUID: challengeCharacteristicUUID);
  }
  factory DeviceInformation.withEssentialsFromJson(Map<String, dynamic> data) {
    final mac = (data['mac'] as String).toUpperCase();
    final serviceUUID = (data['service_uuid'] as String).toUpperCase();
    final challengeCharacteristicUUID =
        (data['lock_char_uuid'] as String).toUpperCase();
    final privKey = data['priv_key'] as String;
    final name = data['ble_name'] as String;
    return DeviceInformation.fromEssentials(
        mac, serviceUUID, challengeCharacteristicUUID, privKey, name);
  }
}
