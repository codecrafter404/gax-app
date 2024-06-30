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
