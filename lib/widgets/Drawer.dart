import 'package:flutter/material.dart';
import 'package:gax_app/pages/EditPage.dart';
import 'package:gax_app/pages/OptionsPage.dart';
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
      icon: const Icon(Icons.widgets_outlined),
      selectedIcon: const Icon(Icons.widgets),
      page: const HomePage(),
      push: false,
    ),
    Destination(
      label: "Scan QR-Code",
      icon: const Icon(Icons.qr_code_outlined),
      selectedIcon: const Icon(Icons.qr_code),
      page: const QRCodeScannerPage(
        isSetup: false,
      ),
      push: false,
    ),
    Destination(
      label: "Edit configuration",
      icon: const Icon(Icons.edit_note_rounded),
      selectedIcon: const Icon(Icons.edit_note_rounded),
      page: const EditPage(
        isSetup: false,
      ),
      push: false,
    ),
    Destination(
      label: "Settings",
      icon: const Icon(Icons.settings),
      selectedIcon: const Icon(Icons.settings),
      page: const OptionsPage(),
      push: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: currentLocation,
      onDestinationSelected: (i) {
        if (i == currentLocation) return;
        Navigator.pop(context);
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
