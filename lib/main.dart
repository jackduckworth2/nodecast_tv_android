import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './login_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  // Try reading url from the shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String            uri   = prefs.getString('url')??'http://192.168.0.90:3000/';

  runApp(MaterialApp(home: LoginPage(uri: uri)));
}

