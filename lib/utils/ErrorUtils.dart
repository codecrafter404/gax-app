import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void displayErrorMessage(BuildContext context, String title, String message) {
  SnackBar bar = SnackBar(
    content: Text(title),
    action: SnackBarAction(
      label: "Show",
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                  },
                  child: const Text("Copy"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, "");
                  },
                  child: const Text("Close"),
                )
              ],
            );
          },
        );
      },
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(bar);
}
