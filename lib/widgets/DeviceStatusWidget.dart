// ignore_for_file: no_logic_in_create_state

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gax_app/pages/OptionsPage.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStatusWidget extends StatefulWidget {
  const DeviceStatusWidget({
    super.key,
    required this.deviceStatus,
  });

  final DeviceInformation deviceStatus;

  @override
  State<DeviceStatusWidget> createState() => _DeviceStatusWidgetState(
        deviceStatus: deviceStatus,
      );
}

class _DeviceStatusWidgetState extends State<DeviceStatusWidget> {
  final DeviceInformation deviceStatus;
  _DeviceStatusWidgetState({required this.deviceStatus});

  late Future<ConfigOptions> future;

  Future<ConfigOptions> loadConfig() async {
    return await ConfigOptions.load();
  }

  late ConfigOptions options;

  @override
  void initState() {
    future = loadConfig();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfigOptions>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData) {
            options = snapshot.data!;
          }

          return Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              buildTableRow(
                "Device connected:",
                widget.deviceStatus.deviceConnected ? "true" : "false",
                widget.deviceStatus.deviceConnected ? Colors.green : Colors.red,
              ),
              buildTableRow(
                "Power-On-Hours:",
                "${((widget.deviceStatus.deviceMetadata?.powerOnHours ?? -1) * 10).round() / 10.0}h",
                Theme.of(context).colorScheme.primary,
              ),
              if (options.advancedMetadata)
                buildTableRow(
                  "Status GPIO-Pin:",
                  "${widget.deviceStatus.deviceMetadata?.statusLEDPin}",
                  Theme.of(context).colorScheme.primary,
                ),
              if (options.advancedMetadata)
                buildTableRow(
                  "Trigger GPIO-Pin:",
                  "${widget.deviceStatus.deviceMetadata?.triggerPin}",
                  Theme.of(context).colorScheme.primary,
                ),
            ],
          );
        });
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
  DeviceMetaData? deviceMetadata;
  String mac;
  String serviceUUID;
  String challengeCharacteristicUUID;
  String metaCharacteristicUUID;
  String logsCharacteristicUUID;
  String privKey;
  List<DeviceLogEntry> logEntries;

  DeviceInformation(
      {required this.deviceName,
      required this.deviceConnected,
      this.deviceMetadata,
      required this.mac,
      required this.privKey,
      required this.logEntries,
      required this.serviceUUID,
      required this.challengeCharacteristicUUID,
      required this.metaCharacteristicUUID,
      required this.logsCharacteristicUUID});
  factory DeviceInformation.fromEssentials(
      String mac,
      String serviceUUID,
      String challengeCharacteristicUUID,
      String privKey,
      String name,
      String metaCharacteristicUUID,
      String logCharacteristicUUID) {
    return DeviceInformation(
        deviceConnected: false,
        deviceName: name,
        mac: mac,
        privKey: privKey,
        logEntries: [],
        serviceUUID: serviceUUID,
        challengeCharacteristicUUID: challengeCharacteristicUUID,
        metaCharacteristicUUID: metaCharacteristicUUID,
        logsCharacteristicUUID: logCharacteristicUUID);
  }
  bool isEqualInformation(DeviceInformation other) {
    return deviceName == other.deviceName && // the rest is state information
        mac == other.mac &&
        serviceUUID == other.serviceUUID &&
        challengeCharacteristicUUID == other.challengeCharacteristicUUID &&
        metaCharacteristicUUID == other.metaCharacteristicUUID &&
        logsCharacteristicUUID == other.logsCharacteristicUUID &&
        privKey == other.privKey;
  }

  factory DeviceInformation.withEssentialsFromJson(Map<String, dynamic> data) {
    final mac = (data['mac'] as String).toUpperCase();
    final serviceUUID = (data['service_uuid'] as String).toUpperCase();
    final challengeCharacteristicUUID =
        (data['lock_char_uuid'] as String).toUpperCase();
    final metaCharacteristicUUID =
        (data['meta_char_uuid'] as String).toUpperCase();
    final logsCharacteristicUUID =
        (data['logs_char_uuid'] as String).toUpperCase();
    final privKey = data['priv_key'] as String;
    final name = data['ble_name'] as String;
    return DeviceInformation.fromEssentials(
        mac,
        serviceUUID,
        challengeCharacteristicUUID,
        privKey,
        name,
        metaCharacteristicUUID,
        logsCharacteristicUUID);
  }
  Map<String, dynamic> toJson() {
    return {
      'mac': mac,
      'service_uuid': serviceUUID,
      'lock_char_uuid': challengeCharacteristicUUID,
      'priv_key': privKey,
      'ble_name': deviceName,
      'meta_char_uuid': metaCharacteristicUUID,
      'logs_char_uuid': logsCharacteristicUUID,
    };
  }

  static Future<DeviceInformation?> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? content = prefs.getString("device_config");
    if (content != null) {
      return DeviceInformation.withEssentialsFromJson(jsonDecode(content));
    }
    return null;
  }

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = jsonEncode(toJson());
    await prefs.setString("device_config", data);
  }
}

class ConfigLoadException implements Exception {
  final String msg;
  ConfigLoadException({required this.msg});
}

class DeviceMetaData {
  double powerOnHours;
  int triggerPin;
  int statusLEDPin;

  DeviceMetaData(
      {required this.powerOnHours,
      required this.triggerPin,
      required this.statusLEDPin});

  factory DeviceMetaData.fromJson(Map<String, dynamic> data) {
    final powerOnHours = data['power_on_hours'] as double;
    final triggerPin = data['trigger_pin'] as int;
    final statusLEDPin = data['status_led_pin'] as int;
    return DeviceMetaData(
      powerOnHours: powerOnHours,
      triggerPin: triggerPin,
      statusLEDPin: statusLEDPin,
    );
  }
}
