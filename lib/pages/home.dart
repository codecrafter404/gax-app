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

      resultMsg = getMessageToErrorCode(result);
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
        if (!deviceStatus.isEqualInformation(res)) {
          deviceStatus = res;
        }
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

  Future<void> readDeviceLogs() async {
    try {
      deviceStatus.logEntries = await readLogs(10, bleDevice!,
          deviceStatus.serviceUUID, deviceStatus.logsCharacteristicUUID);
      // deviceStatus.logEntries = deviceStatus.logEntries.reversed.toList();
    } catch (e) {
      throw DeviceLogReadException(msg: e.toString());
    }
  }

  Future<bool> initAsyncState() async {
    bool shouldSetup = await loadInformation();
    if (shouldSetup) return true;
    await initBLEDevice();
    await readDevicMetadata();
    await readDeviceLogs();
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
      case DeviceLogReadException:
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => displayErrorMessage(
            context,
            "[📲] Failed to read logs",
            (e as DeviceLogReadException).msg.toString(),
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

  ConnectionAction currentAction = ConnectionAction.connecting;

  void setupStateChangeStream(BuildContext context) {
    deviceStatusChangedStream ??= bleDevice?.connectionState.listen(
      (x) async {
        if (context.mounted) {
          bool isConnected = x == BluetoothConnectionState.connected;
          setState(() {
            deviceStatus.deviceConnected = isConnected;
            currentAction = ConnectionAction.idle;
            if (!isConnected) {
              deviceStatus.deviceConnected = false;
              deviceStatus.deviceMetadata = null;
              deviceStatus.logEntries = [];
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
          currentAction == ConnectionAction.idle
              ? IconButton(
                  icon: deviceStatus.deviceConnected
                      ? const Icon(FontAwesomeIcons.linkSlash)
                      : const Icon(FontAwesomeIcons.link),
                  onPressed: () async {
                    if (currentAction != ConnectionAction.idle) {
                      displayErrorMessage(
                          context,
                          "[⏳] The device is currently (dis-)connecting",
                          "WAAAIT a got deam minute!😠");
                    }
                    if (deviceStatus.deviceConnected) {
                      setState(() {
                        currentAction = ConnectionAction.disconnecting;
                      });
                      try {
                        await bleDevice?.disconnect();
                        bleDevice = null;
                        await deviceStatusChangedStream?.cancel();
                        deviceStatusChangedStream = null;
                        setState(() {
                          deviceStatus.deviceConnected = false;
                          deviceStatus.deviceMetadata = null;
                          deviceStatus.logEntries = [];
                        });
                      } catch (e) {
                        setState(() {
                          currentAction = ConnectionAction.idle;
                        });
                        if (context.mounted) {
                          displayErrorMessage(context,
                              "[🔗] Failed to disconnect", e.toString());
                        } else {
                          print(e);
                        }
                      }
                    } else {
                      setState(() {
                        currentAction = ConnectionAction.connecting;
                      });
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
                        setState(() {}); // update ui
                      } catch (e) {
                        if (context.mounted) {
                          setState(() {
                            currentAction = ConnectionAction.idle;
                          });
                          handleAsyncInitError(context, e);
                        }
                      }
                    }
                  },
                )
              : CircularProgressIndicator()
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
                    (_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRCodeScannerPage(
                        isSetup: true,
                      ),
                    ),
                  );

                  currentAction = ConnectionAction.idle;
                });
              } else {
                setupStateChangeStream(context);
              }
            } else if (snapshot.hasError) {
              var e = snapshot.error!;
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => currentAction = ConnectionAction.idle);
              handleAsyncInitError(context, e);
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (snapshot.connectionState != ConnectionState.done ||
                    currentAction != ConnectionAction.idle) {
                  displayErrorMessage(context, "[⏳] Currently loading",
                      "The app has not jet finished loading");
                  return;
                }
                try {
                  bool shouldSetup = await initAsyncState();
                  if (!shouldSetup) {
                    setupStateChangeStream(context);
                  }
                  setState(() {}); // update ui
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

class DeviceLogReadException implements Exception {
  final String msg;
  DeviceLogReadException({required this.msg});
}

String getMessageToErrorCode(int code) {
  String res = "the gate has been openend (successfully): $code";
  switch (code) {
    case 0:
      res = "the gate has been openend successfully: $code";
      break;
    case 1:
      res = "To short response; see console";
      break;
    case 2:
      res = "Invalid signature; see console";
      break;
    case 4:
      res =
          "The signature isn't valid; see console & ensure you've got the right private key";
      break;
    case 5:
      res = "Internal Mutex-Lock error; see console";
      break;
    case 6:
      res = "The server couldn't find the challenge; try again";
      break;
    case 7:
      res = "The challenge has been expired; try again";
      break;
    case 8:
      res =
          "The internal communication between threads didn't work; see console";
      break;
  }
  return res;
}

enum ConnectionAction { connecting, disconnecting, idle }
