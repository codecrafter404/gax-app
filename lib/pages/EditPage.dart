import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gax_app/pages/home.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';
import 'package:gax_app/widgets/Drawer.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key, this.deviceInfo, required this.isSetup});
  final DeviceInformation? deviceInfo;
  final bool isSetup;

  @override
  State<EditPage> createState() =>
      EditPageState(deviceInfo: deviceInfo, isSetup: isSetup);
}

class EditPageState extends State<EditPage> {
  final bool isSetup;
  EditPageState({this.deviceInfo, required this.isSetup});
  final _formKey = GlobalKey<FormState>();
  DeviceInformation? deviceInfo;

  late Future<DeviceInformation?> future;
  Future<DeviceInformation?> loadConfiguration() async {
    return await DeviceInformation.load();
  }

  @override
  void initState() {
    future = loadConfiguration();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Edit the configuration"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                try {
                  await deviceInfo!.save();
                  if (context.mounted) {
                    displayErrorMessage(
                        context, "Saved😀", "The settings have been updated");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    displayErrorMessage(
                        context, "Failed to save config", e.toString());
                  } else {
                    print(e);
                  }
                }
              } else {
                displayErrorMessage(
                    context, "Fill in the required fields.", "do it 😠");
              }
            },
          )
        ],
      ),
      drawer: !isSetup
          ? AppDrawer(
              currentLocation: 2,
            )
          : null,
      body: FutureBuilder<DeviceInformation?>(
          future: deviceInfo == null ? future : null,
          builder: (BuildContext context,
              AsyncSnapshot<DeviceInformation?> snapshot) {
            if (snapshot.hasError) {
              var e = snapshot.error!;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => displayErrorMessage(
                  context,
                  "[⚙️] Failed to read configuration",
                  e.toString(),
                ),
              );
            } else if (snapshot.hasData) {
              deviceInfo = snapshot.data;
            }

            if (snapshot.connectionState != ConnectionState.done &&
                deviceInfo == null) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "device name",
                        border: OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      initialValue: deviceInfo?.deviceName,
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "device name is required";
                        return null;
                      },
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                "", "", "", "", x, "");
                          } else {
                            deviceInfo!.deviceName = x;
                          }
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "MAC-Address",
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                      initialValue: deviceInfo?.mac,
                      autovalidateMode: AutovalidateMode.always,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "MAC-Address is required";
                        if (!RegExp("^([A-F\\d]{2}:){5}[A-F\\d]{2}\$")
                            .hasMatch(x)) return "Format: XX:XX:XX:XX:XX:XX";
                        return null;
                      },
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                x, "", "", "", "", "");
                          } else {
                            deviceInfo!.mac = x;
                          }
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      autocorrect: false,
                      autovalidateMode: AutovalidateMode.always,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                      initialValue: deviceInfo?.privKey,
                      decoration: const InputDecoration(
                        labelText: "Private Key",
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                "", "", "", x, "", "");
                          } else {
                            deviceInfo!.privKey = x;
                          }
                        }
                      },
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "Private Key is required";
                        if (!RegExp(
                                "^(?:[A-Za-z0-9+\\/]{4})*(?:[A-Za-z0-9+\\/]{4}|[A-Za-z0-9+\\/]{3}=|[A-Za-z0-9+\\/]{2}={2})\$")
                            .hasMatch(x))
                          return "The key must be base64 encoded";
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      autocorrect: false,
                      autovalidateMode: AutovalidateMode.always,
                      inputFormatters: [UpperCaseTextFormatter()],
                      initialValue: deviceInfo?.serviceUUID,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: "Service-UUID",
                        border: OutlineInputBorder(),
                      ),
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "Service-UUID is required";
                        if (!RegExp(
                                "^[A-F\\d]{8}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{12}\$")
                            .hasMatch(x))
                          return "Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
                        return null;
                      },
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                "", x, "", "", "", "");
                          } else {
                            deviceInfo!.serviceUUID = x;
                          }
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      autocorrect: false,
                      autovalidateMode: AutovalidateMode.always,
                      initialValue: deviceInfo?.challengeCharacteristicUUID,
                      decoration: const InputDecoration(
                        labelText: "ChallangeCharacteristic-UUID",
                        border: OutlineInputBorder(),
                      ),
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "ChallangeCharacteristic-UUID is required";
                        if (!RegExp(
                                "^[A-F\\d]{8}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{12}\$")
                            .hasMatch(x))
                          return "Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
                        return null;
                      },
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                "", "", x, "", "", "");
                          } else {
                            deviceInfo!.challengeCharacteristicUUID = x;
                          }
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: TextFormField(
                      autocorrect: false,
                      autovalidateMode: AutovalidateMode.always,
                      initialValue: deviceInfo?.metaCharacteristicUUID,
                      decoration: const InputDecoration(
                        labelText: "MetaCharacteristic-UUID",
                        border: OutlineInputBorder(),
                      ),
                      validator: (x) {
                        if (x == null || x.isEmpty)
                          return "MetaCharacteristic-UUID is required";
                        if (!RegExp(
                                "^[A-F\\d]{8}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{4}-[A-F\\d]{12}\$")
                            .hasMatch(x))
                          return "Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
                        return null;
                      },
                      onSaved: (x) {
                        if (x != null) {
                          if (deviceInfo == null) {
                            DeviceInformation.fromEssentials(
                                "", "", "", "", "", x);
                          } else {
                            deviceInfo!.metaCharacteristicUUID = x;
                          }
                        }
                      },
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
        text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
