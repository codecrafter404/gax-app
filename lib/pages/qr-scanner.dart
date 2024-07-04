import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gax_app/pages/EditPage.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';
import 'package:gax_app/widgets/Drawer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerPage extends StatefulWidget {
  final bool isSetup;
  const QRCodeScannerPage({super.key, required this.isSetup});

  @override
  State<QRCodeScannerPage> createState() =>
      _QRCodeScannerPageState(isSetup: isSetup);
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage>
    with WidgetsBindingObserver, RouteAware {
  final bool isSetup;
  _QRCodeScannerPageState({required this.isSetup});

  // QR-Code controller stuff
  final MobileScannerController controller = MobileScannerController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        unawaited(controller.stop());
    }
  }

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);

    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Scan the QR-Code"),
        actions: widget.isSetup
            ? [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.penToSquare),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditPage(
                          isSetup: true,
                        ),
                      ),
                    );
                  },
                )
              ]
            : [],
      ),
      drawer: !widget.isSetup
          ? AppDrawer(
              currentLocation: 1,
            )
          : null,
      body: StreamBuilder<BarcodeCapture>(
          stream: controller.barcodes,
          builder: (context, snapshot) {
            // handle stream here

            if (snapshot.hasData) {
              BarcodeCapture x = snapshot.data!;
              if (x.barcodes.isNotEmpty) {
                if (x.barcodes[0].rawValue != null) {
                  String data = x.barcodes[0].rawValue!;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      try {
                        DeviceInformation parsed =
                            DeviceInformation.withEssentialsFromJson(
                                jsonDecode(data));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPage(
                              deviceInfo: parsed,
                              isSetup: widget.isSetup,
                            ),
                          ),
                        );
                      } catch (e) {
                        displayErrorMessage(context, "Failed to parse qr-code",
                            "A code has been read but could not been parsed: $e");
                      }
                    },
                  );
                }
              }
            }
            return Align(
              alignment: Alignment.center,
              child: MobileScanner(
                controller: controller,
              ),
            );
          }),
    );
  }
}
