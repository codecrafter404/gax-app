import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyErrorWidget extends StatelessWidget {
  final Object e;
  const CopyErrorWidget({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error),
          Text(
            "An error occured:",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            e.toString(),
            textAlign: TextAlign.center,
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: e.toString()));
            },
          )
        ],
      ),
    );
  }
}
