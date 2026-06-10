import 'package:flutter/material.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/pages/main/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BridgeFlutterApi.setUp(AppFlutterApi());
  try {
    await AppHostApi().initTunFilesDir();
  } catch (_) {
    // Pigeon channel not ready — continue without cached tun dir
  }
  runApp(GoRouteApp());
}
