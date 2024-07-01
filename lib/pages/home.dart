import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gax_app/utils/BLEUtil.dart';
import 'package:gax_app/utils/ChallengeUtils.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';
import 'package:local_auth/local_auth.dart';

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
      "UP7mKbCTI9wyP/wvOtQCtERckziLTC+gDo83tzAPQ18=", // only for testing purposes
      "GAX 0.1");
  BluetoothDevice? bleDevice;
  StreamSubscription<BluetoothConnectionState>? deviceStatusChangedStream;

  Future<bool> initBLEDevice(BuildContext context) async {
    try {
      if (!(await FlutterBluePlus.isSupported))
        throw Exception("Your device doesn't support BLE");
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
      return true;
    } catch (e) {
      print(e.toString());
      if (context.mounted)
        displayErrorMessage(context, "[🔌] failed to connect", e.toString());
    }
    return false;
  }

  Future<void> openGate(BuildContext context) async {
    String resultMsg = "Empty result message";
    bool successful = false;
    try {
      if (!(await initBLEDevice(context))) {
        return;
      }

      // local auth
      LocalAuthentication auth = LocalAuthentication();
      if ((await auth.isDeviceSupported()) || (await auth.canCheckBiometrics)) {
        bool isAuthenticated = await auth.authenticate(
            localizedReason: "Please authenticate to open the gate");

        if (!isAuthenticated)
          throw Exception("You've not authenticated yourself; try again");
      }

      List<int> challengeBytes =
          await readChallengeBytes(10, bleDevice!, deviceStatus.serviceUUID);
      List<int> solution = signChallenge(challengeBytes, deviceStatus.privKey);
      int result = await writeChallengeBytes(
          10, bleDevice!, solution, deviceStatus.serviceUUID);

      resultMsg = "the gate has been openend (successfully): $result";
      switch (result) {
        case 0:
          resultMsg = "the gate has been openend successfully: $result";
          break;
        case 1:
          resultMsg = "To short response; see console";
          break;
        case 2:
          resultMsg = "Invalid signature; see console";
          break;
        case 4:
          resultMsg =
              "The signature isn't valid; see console & ensure you've got the right private key";
          break;
        case 5:
          resultMsg = "Internal Mutex-Lock error; see console";
          break;
        case 6:
          resultMsg = "The server couldn't find the challenge; try again";
          break;
        case 7:
          resultMsg = "The challenge has been expired; try again";
          break;
        case 8:
          resultMsg =
              "The internal communication between threads didn't work; see console";
          break;
      }
      successful = result == 0;
    } on InvalidBluetoothDeviceStateException catch (e) {
      resultMsg =
          "Invalid device state: ${e.msg}; verify the configuration for correctness";
    } on DeviceNotConnectedException {
      resultMsg = "The device is currently disconnected; try again";
    } catch (e) {
      print(e.toString());
      resultMsg = e.toString();
    }
    displayErrorMessage(
        context,
        successful ? "[🔓] opened successful" : "[🔒] Failed to open gate",
        resultMsg);
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
          initBLEDevice(context);
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
          await openGate(context);
        },
        tooltip: 'Increment',
        label: const Text("Open"),
        icon: const Icon(Icons.lock_open_rounded),
      ),
    );
  }
}
