import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            );
          },
        );
      },
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(bar);
}
