import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
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
        const NavigationDrawerDestination(
          label: Text("Home"),
          icon: Icon(Icons.widgets_outlined),
          selectedIcon: Icon(Icons.widgets),
        ),
        const NavigationDrawerDestination(
          label: Text("Scan QR-Code"),
          icon: Icon(Icons.qr_code_scanner_rounded),
          selectedIcon: Icon(Icons.qr_code_outlined),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: RichText(
                text: TextSpan(children: [TextSpan(), TextSpan()])), // credits
          ),
        )
      ],
    );
  }
}
