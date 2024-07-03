import 'package:flutter/material.dart';
import 'package:gax_app/widgets/Drawer.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Edit the configuration"),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              _formKey.currentState!.validate();
            },
          )
        ],
      ),
      drawer: AppDrawer(
        currentLocation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  icon: Icon(Icons.heart_broken),
                  labelText: "device name",
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.always,
                validator: (x) {
                  if (x == null || x.isEmpty) return "device name is required";
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  icon: Icon(Icons.heart_broken),
                  labelText: "MAC-Address",
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.always,
                validator: (x) {
                  if (x == null || x.isEmpty) return "MAC-Address is required";
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  icon: Icon(Icons.heart_broken),
                  labelText: "Private Key",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  icon: Icon(Icons.heart_broken),
                  labelText: "Service-UUID",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  icon: Icon(Icons.heart_broken),
                  labelText: "ChallangeCharacteristic-UUID",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
