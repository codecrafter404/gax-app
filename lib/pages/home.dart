import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gax_app/pages/qr-scanner.dart';
import 'package:gax_app/utils/BLEUtil.dart';
import 'package:gax_app/utils/ChallengeUtils.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceLogs.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';
import 'package:gax_app/widgets/Drawer.dart';
import 'package:local_auth/local_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  final String title = "GA-X";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeviceInformation deviceStatus = DeviceInformation.fromEssentials(
      "Loading...",
      "Loading...",
      "Loading...",
      "Loading...",
      "Loading...",
      "Loading...");
  BluetoothDevice? bleDevice;
  StreamSubscription<BluetoothConnectionState>? deviceStatusChangedStream;

  Future<void> initBLEDevice() async {
    try {
      if (!(await FlutterBluePlus.isSupported)) {
        throw Exception("Your device doesn't support BLE");
      }
      if (bleDevice == null || bleDevice!.isDisconnected) {
        bleDevice = await scanAndConnect(10, deviceStatus);
      }
    } catch (e) {
      throw BleInitException(msg: e.toString());
    }
  }

  Future<void> openGate(BuildContext context) async {
    String resultMsg = "Empty result message";
    bool successful = false;
    try {
      await initBLEDevice();
      // local auth
      LocalAuthentication auth = LocalAuthentication();
      if (await auth.isDeviceSupported()) {
        bool isAuthenticated = await auth.authenticate(
          localizedReason: "Please authenticate to open the gate",
          options: const AuthenticationOptions(
            biometricOnly: false,
          ),
        );

        if (!isAuthenticated) {
          throw Exception("You've not authenticated yourself; try again");
        }
      }

      List<int> challengeBytes = await readChallengeBytes(10, bleDevice!,
          deviceStatus.serviceUUID, deviceStatus.challengeCharacteristicUUID);
      List<int> solution = signChallenge(challengeBytes, deviceStatus.privKey);
      int result = await writeChallengeBytes(10, bleDevice!, solution,
          deviceStatus.serviceUUID, deviceStatus.challengeCharacteristicUUID);

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
    if (context.mounted) {
      displayErrorMessage(
          context,
          successful ? "[🔓] opened successful" : "[🔒] Failed to open gate",
          resultMsg);
    }
  }

  late Future<bool> future;

  @override
  void initState() {
    future = initAsyncState();
    super.initState();
  }

  @override
  void dispose() {
    deviceStatusChangedStream?.cancel();
    if (bleDevice != null) {
      // bleDevice!.disconnect();
    }
    super.dispose();
  }

  //Returns a bool indecating if the you should navigate to the setup screen or not
  Future<bool> loadInformation() async {
    try {
      var res = await DeviceInformation.load();
      if (res != null) {
        deviceStatus = res;
      } else {
        return true;
      }
    } catch (e) {
      throw ConfigLoadException(msg: e.toString());
    }
    return false;
  }

  Future<void> readDevicMetadata() async {
    try {
      deviceStatus.deviceMetadata = await readMetadata(10, bleDevice!,
          deviceStatus.serviceUUID, deviceStatus.metaCharacteristicUUID);
    } catch (e) {
      throw MetaDataReadException(msg: e.toString());
    }
  }

  Future<bool> initAsyncState() async {
    bool shouldSetup = await loadInformation();
    if (shouldSetup) return true;
    await initBLEDevice();
    await readDevicMetadata();
    return false;
  }

  void handleAsyncInitError(BuildContext context, Object e) {
    switch (e.runtimeType) {
      case BleInitException:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => displayErrorMessage(
            context,
            "[🔌] failed to connect",
            (e as BleInitException).msg.toString(),
          ),
        );
        break;
      case ConfigLoadException:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => displayErrorMessage(
            context,
            "[⚙️] Failed to read configuration",
            (e as ConfigLoadException).msg.toString(),
          ),
        );
        break;
      case MetaDataReadException:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => displayErrorMessage(
            context,
            "[📲] Failed to read metadata",
            (e as MetaDataReadException).msg.toString(),
          ),
        );
        break;
      default:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => displayErrorMessage(
            context,
            "[⚡] An error during initalization occured",
            e.toString(),
          ),
        );
        break;
    }
  }

  void setupStateChangeStream(BuildContext context) {
    deviceStatusChangedStream ??= bleDevice?.connectionState.listen(
      (x) async {
        if (context.mounted) {
          bool isConnected = x == BluetoothConnectionState.connected;
          setState(() {
            deviceStatus.deviceConnected = isConnected;
            if (!deviceStatus.deviceConnected) {
              deviceStatus.deviceMetadata = null;
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: deviceStatus.deviceConnected
                ? Icon(FontAwesomeIcons.linkSlash)
                : Icon(FontAwesomeIcons.link),
            onPressed: () async {
              if (deviceStatus.deviceConnected) {
                try {
                  await bleDevice?.disconnect();
                  bleDevice = null;
                  await deviceStatusChangedStream?.cancel();
                  deviceStatusChangedStream = null;
                } catch (e) {
                  if (context.mounted) {
                    displayErrorMessage(
                        context, "[🔗] Failed to disconnect", e.toString());
                  } else {
                    print(e);
                  }
                }
              } else {
                try {
                  bool shouldSetup = await initAsyncState();
                  if (!shouldSetup) {
                    setupStateChangeStream(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRCodeScannerPage(
                          isSetup: true,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    handleAsyncInitError(context, e);
                  }
                }
              }
            },
          )
        ],
      ),
      drawer: AppDrawer(
        currentLocation: 0,
      ),
      body: FutureBuilder<bool>(
          future: future,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!) {
                // Intro
                WidgetsBinding.instance.addPostFrameCallback(
                  // after the page has been rendered!
                  (_) => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRCodeScannerPage(
                        isSetup: true,
                      ),
                    ),
                  ),
                );
              } else {
                setupStateChangeStream(context);
              }
            } else if (snapshot.hasError) {
              var e = snapshot.error!;
              handleAsyncInitError(context, e);
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (snapshot.connectionState != ConnectionState.done) {
                  displayErrorMessage(context, "[⏳] Currently loading",
                      "The app has not jet finished loading");
                  return;
                }
                try {
                  bool shouldSetup = await initAsyncState();
                  if (!shouldSetup) {
                    setupStateChangeStream(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    handleAsyncInitError(context, e);
                  }
                }
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
                                subtitle: DeviceStatusWidget(
                                    deviceStatus: deviceStatus),
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
            );
          }),
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

class BleInitException implements Exception {
  final String msg;
  BleInitException({required this.msg});
}

class MetaDataReadException implements Exception {
  final String msg;
  MetaDataReadException({required this.msg});
}
