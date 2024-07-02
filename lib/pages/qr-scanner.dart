import 'package:flutter/material.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/Drawer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerPage extends StatelessWidget {
  const QRCodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Scan the QR-Code"),
      ),
      drawer: AppDrawer(
        currentLocation: 1,
      ),
      body: Align(
        alignment: Alignment.center,
        child: MobileScanner(
          onDetect: (x) {
            displayErrorMessage(
                context, "Scanned QR-Code", x.barcodes[0].rawValue!);
          },
        ),
      ),
    );
  }
}
