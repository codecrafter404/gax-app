import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gax_app/pages/EditPage.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/DeviceStatusWidget.dart';
import 'package:gax_app/widgets/Drawer.dart';
import 'package:gax_app/widgets/ErrorWidget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerPage extends StatelessWidget {
  final bool isSetup;
  const QRCodeScannerPage({super.key, required this.isSetup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Scan the QR-Code"),
        actions: isSetup
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
      drawer: !isSetup
          ? AppDrawer(
              currentLocation: 1,
            )
          : null,
      body: Align(
        alignment: Alignment.center,
        child: MobileScanner(
          errorBuilder:
              (BuildContext context, MobileScannerException e, Widget? _) {
            return CopyErrorWidget(e: e);
          },
          onDetect: (x) {
            if (x.barcodes.isNotEmpty) {
              if (x.barcodes[0].rawValue != null) {
                String data = x.barcodes[0].rawValue!;

                try {
                  DeviceInformation parsed =
                      DeviceInformation.withEssentialsFromJson(
                          jsonDecode(data));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPage(
                        deviceInfo: parsed,
                        isSetup: isSetup,
                      ),
                    ),
                  );
                } catch (e) {
                  displayErrorMessage(context, "Failed to parse qr-code",
                      "A code has been read but could not been parsed: $e");
                }
              }
            }
          },
        ),
      ),
    );
  }
}
