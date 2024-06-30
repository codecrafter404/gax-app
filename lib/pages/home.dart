import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gax_app/utils/BLEUtil.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeviceInformation deviceStatus = DeviceInformation.fromEssentials(
      "3C:61:05:30:B3:CE",
      "5f9b34fb-0000-1000-8000-00805f9b34fb",
      "privateKey",
      "GAX 0.1");
  BluetoothDevice? bleDevice;
  StreamSubscription<BluetoothConnectionState>? deviceStatusChangedStream;

  Future<void> updateDeviceStatus(BuildContext context) async {
    try {
      if (bleDevice == null || bleDevice!.isDisconnected) {
        bleDevice = await scanAndConnect(10, deviceStatus);
        deviceStatusChangedStream =
            bleDevice!.connectionState.listen((x) async {
          setState(() {
            deviceStatus.deviceConnected =
                x == BluetoothConnectionState.connected;
          });
        });
      }
    } catch (e) {
      print(e.toString());
      if (context.mounted)
        displayErrorMessage(context, "🔌failed to connect", e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    deviceStatusChangedStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          updateDeviceStatus(context);
        },
        child: Stack(
          // Workaround to allow refreshing without an ListView()
          children: [
            ListView(),
            Column(
              children: [
                Center(
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(deviceStatus.deviceConnected
                              ? Icons.bluetooth_connected_rounded
                              : Icons.bluetooth_rounded),
                          title: Text(deviceStatus.deviceName),
                          subtitle:
                              DeviceStatusWidget(deviceStatus: deviceStatus),
                        )
                      ],
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(17, 0, 17, 0),
                //   child: Divider(),
                // ),
                Expanded(
                  child: DeviceLogs(
                    logs: deviceStatus.logEntries,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          updateDeviceStatus(context);
        },
        tooltip: 'Increment',
        label: const Text("Open"),
        icon: const Icon(Icons.lock_open_rounded),
      ),
    );
  }
}
