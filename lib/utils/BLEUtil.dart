import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';

Future<BluetoothDevice> scanAndConnect(
    int timeoutAfter, DeviceInformation deviceInfo) async {
  StreamSubscription<List<ScanResult>>? devicesStream;
  ScanResult? device;
  try {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off &&
        Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    devicesStream = FlutterBluePlus.onScanResults.listen((devices) async {
      if (devices.isNotEmpty) {
        device = devices.firstWhere((x) {
          print(x.toString());
          return x.advertisementData.serviceUuids
                  .contains(Guid.fromString(deviceInfo.serviceUUID)) &&
              x.advertisementData.advName == deviceInfo.deviceName &&
              _compareRemoteIDToMacAddress(x.device.remoteId, deviceInfo.mac);
        });
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

    if (device == null) {
      throw TimeoutException("Failed to find device in given Timeframe");
    }

    device!.device.connect(timeout: Duration(seconds: timeoutAfter));
    // await device!.device.connectionState.firstWhere((x) {
    //   return BluetoothConnectionState.connected == x;
    // });
    return device!.device;
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

BluetoothCharacteristic getChallengeCharacteristic(BluetoothDevice device) {
  BluetoothService service;
  try {
    service = device.servicesList.firstWhere((x) {
      return x.serviceUuid ==
          Guid.fromString("5f9b34fb-0000-1000-8000-00805f9b34fb");
    });
  } catch (e) {
    throw InvalidBluetoothDeviceStateException(msg: "Service not found");
  }

  BluetoothCharacteristic challengeCharacteristic;
  try {
    challengeCharacteristic = service.characteristics.firstWhere((x) {
      return x.characteristicUuid ==
          Guid.fromString("00000000-DEAD-BEEF-0001-000000000000");
    });
  } catch (e) {
    throw InvalidBluetoothDeviceStateException(
        msg: "Challenge characteristic not found");
  }

  return challengeCharacteristic;
}

Future<List<int>> readChallengeBytes(
    int timeoutAfter, BluetoothDevice device) async {
  if (!device.isConnected) {
    throw DeviceNotConnectedException();
  }

  BluetoothCharacteristic challengeCharacteristic =
      getChallengeCharacteristic(device);
  List<int> data = await challengeCharacteristic.read(timeout: timeoutAfter);
  return data;
}

Future<int> writeChallengeBytes(
    int timeoutAfter, BluetoothDevice device, List<int> data) async {
  BluetoothCharacteristic challengeCharacteristic =
      getChallengeCharacteristic(device);
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
}
