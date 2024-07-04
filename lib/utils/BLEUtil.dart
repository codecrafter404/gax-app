import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';

Future<BluetoothDevice> scanAndConnect(
    int timeoutAfter, DeviceInformation deviceInfo) async {
  StreamSubscription<List<ScanResult>>? devicesStream;
  BluetoothDevice? device;
  try {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off &&
        Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    // first search in system devices
    List<BluetoothDevice> systemdevices = await FlutterBluePlus.systemDevices;
    List<BluetoothDevice> canidates = systemdevices.where((x) {
      return x.platformName == deviceInfo.deviceName &&
          _compareRemoteIDToMacAddress(x.remoteId, deviceInfo.mac);
    }).toList();
    if (canidates.isNotEmpty) {
      device = canidates[0]; // grab the first one
    }

    // check bonded devices
    if (device == null) {
      // handle bonded devices
      List<BluetoothDevice> bonded =
          (await FlutterBluePlus.bondedDevices).where((x) {
        return x.platformName == deviceInfo.deviceName &&
            _compareRemoteIDToMacAddress(x.remoteId, deviceInfo.mac);
      }).toList();
      if (bonded.isNotEmpty) {
        device = bonded[0];
      }
    }

    // then scan for all devices
    if (device == null) {
      devicesStream = FlutterBluePlus.onScanResults.listen((devices) async {
        print(devices.toString());
        if (devices.isNotEmpty) {
          device = devices.firstWhere((x) {
            return x.advertisementData.serviceUuids
                    .contains(Guid.fromString(deviceInfo.serviceUUID)) &&
                x.advertisementData.advName == deviceInfo.deviceName &&
                _compareRemoteIDToMacAddress(x.device.remoteId, deviceInfo.mac);
          }).device;
        }
      });

      await FlutterBluePlus.startScan(
        withNames: [deviceInfo.deviceName],
        timeout: Duration(seconds: timeoutAfter),
      );

      DateTime timeout = DateTime.now().add(Duration(seconds: timeoutAfter));
      while (DateTime.now().compareTo(timeout) < 0) {
        if (device != null) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (device == null) {
      throw TimeoutException("Failed to find device in given Timeframe");
    }

    device!.connect(timeout: Duration(seconds: timeoutAfter));

    // wait for the connection to establish successfully

    DateTime connectTimeout =
        DateTime.now().add(Duration(seconds: timeoutAfter));

    while (DateTime.now().compareTo(connectTimeout) < 0) {
      if (device!.isConnected) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (DateTime.now().compareTo(connectTimeout) == 1) {
      throw InvalidBluetoothDeviceStateException(msg: "Connection timed out");
    }
    // await device!.device.connectionState.firstWhere((x) {
    //   return BluetoothConnectionState.connected == x;
    // });
    return device!;
  } catch (e) {
    rethrow;
  } finally {
    if (devicesStream != null) await devicesStream.cancel();
  }
}

bool _compareRemoteIDToMacAddress(DeviceIdentifier remoteId, String mac) {
  if (Platform.isAndroid) {
    return remoteId.toString() == mac;
  }
  return true;
}

Future<BluetoothCharacteristic> getCharacteristic(BluetoothDevice device,
    String bleServiceUuid, String bleChallengeCharacteristic) async {
  BluetoothService service;
  await device.discoverServices(timeout: 10);
  try {
    print(device);
    service = device.servicesList.firstWhere((x) {
      return x.serviceUuid == Guid.fromString(bleServiceUuid);
    });
  } catch (e) {
    throw InvalidBluetoothDeviceStateException(msg: "Service not found");
  }

  BluetoothCharacteristic challengeCharacteristic;
  try {
    challengeCharacteristic = service.characteristics.firstWhere((x) {
      return x.characteristicUuid ==
          Guid.fromString(bleChallengeCharacteristic);
    });
  } catch (e) {
    throw InvalidBluetoothDeviceStateException(
        msg: "Challenge characteristic not found");
  }

  return challengeCharacteristic;
}

Future<List<int>> readChallengeBytes(int timeoutAfter, BluetoothDevice device,
    String bleServiceUuid, String bleChallengeCharacteristic) async {
  if (!device.isConnected) {
    throw DeviceNotConnectedException();
  }

  BluetoothCharacteristic challengeCharacteristic = await getCharacteristic(
      device, bleServiceUuid, bleChallengeCharacteristic);
  List<int> data = await challengeCharacteristic.read(timeout: timeoutAfter);
  return data;
}

Future<DeviceMetaData> readMetadata(int timeoutAfter, BluetoothDevice device,
    String bleServiceUuid, String bleMetaCharacteristic) async {
  if (!device.isConnected) {
    throw DeviceNotConnectedException();
  }

  BluetoothCharacteristic metaCharacteristic =
      await getCharacteristic(device, bleServiceUuid, bleMetaCharacteristic);
  List<int> data = await metaCharacteristic.read(timeout: timeoutAfter);
  if (data.isEmpty) {
    throw InvalidBluetoothDeviceStateException(
        msg: "The firmware failed to provide the metadata; see console");
  }
  try {
    DeviceMetaData res = DeviceMetaData.fromJson(jsonDecode(utf8.decode(data)));
    return res;
  } catch (e) {
    throw BluetoothParseException(msg: e.toString());
  }
}

Future<List<DeviceLogEntry>> readLogs(int timeoutAfter, BluetoothDevice device,
    String bleServiceUuid, String logCharacteristicUuid) async {
  if (!device.isConnected) {
    throw DeviceNotConnectedException();
  }

  BluetoothCharacteristic logsCharacteristic =
      await getCharacteristic(device, bleServiceUuid, logCharacteristicUuid);
  List<int> data = await logsCharacteristic.read(timeout: timeoutAfter);
  if (data.isEmpty) {
    throw InvalidBluetoothDeviceStateException(
        msg: "The firmware failed to provide the logs; see console");
  }
  try {
    Iterable i = jsonDecode(utf8.decode(data));
    List<DeviceLogEntry> res = List<DeviceLogEntry>.from(
        i.map((model) => DeviceLogEntry.fromJson(model)));
    return res;
  } catch (e) {
    throw BluetoothParseException(msg: e.toString());
  }
}

Future<int> writeChallengeBytes(
    int timeoutAfter,
    BluetoothDevice device,
    List<int> data,
    String bleServiceUuid,
    String bleChallengeCharacteristic) async {
  BluetoothCharacteristic challengeCharacteristic = await getCharacteristic(
      device, bleServiceUuid, bleChallengeCharacteristic);
  try {
    await challengeCharacteristic.write(data);
    return 0;
  } on FlutterBluePlusException catch (e) {
    if (!(e.function == "writeCharacteristic" && e.code != null)) {
      rethrow;
    }
    return e.code!;
  }
}

class DeviceNotConnectedException implements Exception {}

class InvalidBluetoothDeviceStateException implements Exception {
  final String msg;
  InvalidBluetoothDeviceStateException({required this.msg});
  @override
  String toString() {
    return "InvalidBluetoothDeviceStateException: $msg";
  }
}

class BluetoothParseException implements Exception {
  final String msg;
  BluetoothParseException({required this.msg});
  @override
  String toString() {
    return "BluetoothParseException: $msg";
  }
}
