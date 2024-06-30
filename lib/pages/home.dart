import 'package:flutter/material.dart';
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
      "DE:AD:BE:EF:00:01",
      "5f9b34fb-0000-1000-8000-00805f9b34fb",
      "privateKey",
      "GA-X");
  Future<void> updateDeviceStatus() async {
    setState(() {
      deviceStatus.deviceConnected = !deviceStatus.deviceConnected;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: updateDeviceStatus,
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
        onPressed: updateDeviceStatus,
        tooltip: 'Increment',
        label: const Text("Open"),
        icon: const Icon(Icons.lock_open_rounded),
      ),
    );
  }
}
