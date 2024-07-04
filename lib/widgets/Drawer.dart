import 'package:flutter/material.dart';
import 'package:gax_app/pages/EditPage.dart';
import 'package:gax_app/pages/home.dart';
import 'package:gax_app/pages/qr-scanner.dart';

class Destination {
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final Widget page;
  final bool push;

  Destination(
      {required this.label,
      required this.icon,
      required this.selectedIcon,
      required this.page,
      required this.push});
}

class AppDrawer extends StatelessWidget {
  AppDrawer({super.key, required this.currentLocation});
  final int currentLocation;
  final List<Destination> destinations = [
    Destination(
      label: "Home",
      icon: Icon(Icons.widgets_outlined),
      selectedIcon: Icon(Icons.widgets),
      page: HomePage(),
      push: false,
    ),
    Destination(
      label: "Scan QR-Code",
      icon: Icon(Icons.qr_code_outlined),
      selectedIcon: Icon(Icons.qr_code),
      page: QRCodeScannerPage(
        isSetup: false,
      ),
      push: false,
    ),
    Destination(
      label: "Edit configuration",
      icon: Icon(Icons.edit_note_rounded),
      selectedIcon: Icon(Icons.edit_note_rounded),
      page: EditPage(
        isSetup: false,
      ),
      push: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: currentLocation,
      onDestinationSelected: (i) {
        if (i == currentLocation) return;
        if (destinations[i].push) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => destinations[i].page));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => destinations[i].page));
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall,
              children: const [
                TextSpan(
                    text: "G", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "ate "),
                TextSpan(
                    text: "A", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "ccess - "),
                TextSpan(
                    text: "X", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        ...destinations.map((x) {
          return NavigationDrawerDestination(
            label: Text(x.label),
            icon: x.icon,
            selectedIcon: x.selectedIcon,
          );
        }),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: const [
                TextSpan(text: "Made with ❤️  by "),
                TextSpan(
                  text: "@Codecrafter404",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ), // credits
        )
      ],
    );
  }
}
