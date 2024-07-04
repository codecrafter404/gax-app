import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gax_app/utils/ErrorUtils.dart';
import 'package:gax_app/widgets/Drawer.dart';
import 'package:gax_app/widgets/ErrorWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  late Future<ConfigOptions> future;

  Future<ConfigOptions> loadConfig() async {
    return await ConfigOptions.load();
  }

  @override
  void initState() {
    future = loadConfig();
    super.initState();
  }

  late ConfigOptions options;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Settings"),
      ),
      drawer: AppDrawer(
        currentLocation: 3,
      ),
      body: FutureBuilder<ConfigOptions>(
          future: future,
          builder:
              (BuildContext context, AsyncSnapshot<ConfigOptions> snapshot) {
            if (snapshot.hasData) {
              options = snapshot.data!;
            }

            if (snapshot.hasError) {
              var e = snapshot.error!;
              return CopyErrorWidget(e: e);
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    "Home Screen",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                SwitchListTile(
                  title: Text("Show advanced Metadata"),
                  subtitle: Text("Shows metadata like GPIO Pins etc."),
                  value: options.advancedMetadata,
                  onChanged: (bool? x) async {
                    if (x != null) {
                      setState(() {
                        options.advancedMetadata = x;
                      });
                      try {
                        await options.save();
                      } catch (e) {
                        if (context.mounted) {
                          displayErrorMessage(
                            context,
                            "Failed to save settings",
                            e.toString(),
                          );
                        }
                      }
                    }
                  },
                )
              ],
            );
          }),
    );
  }
}

class ConfigOptions {
  bool advancedMetadata;
  ConfigOptions({required this.advancedMetadata});

  Map<String, dynamic> toJson() {
    return {
      'advanced_metadata': advancedMetadata,
    };
  }

  factory ConfigOptions.fromJson(Map<String, dynamic> data) {
    final advancedMetadata = data['advanced_metadata'] as bool;
    return ConfigOptions(
      advancedMetadata: advancedMetadata,
    );
  }
  static Future<ConfigOptions> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? settings = prefs.getString("settings");
    if (settings == null) {
      return ConfigOptions(advancedMetadata: false);
    }
    ConfigOptions opts = ConfigOptions.fromJson(jsonDecode(settings));
    return opts;
  }

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("settings", jsonEncode(toJson()));
  }
}
