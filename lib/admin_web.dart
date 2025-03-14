import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  AdminAppState createState() => AdminAppState();
}

class AdminAppState extends State<AdminApp> {
  final webviewController = WebviewController();
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  // Fonction pour initialiser la WebView
  void _initializeWebView() async {
    await webviewController.initialize();
    _loadHtmlFromAssets(webviewController);
    setState(() {
      _isWebViewInitialized = true;
    });
  }

  // Fonction pour charger le fichier HTML local
  void _loadHtmlFromAssets(WebviewController controller) async {
    String fileText = await rootBundle.loadString('index.html');
    controller.loadUrl(Uri.dataFromString(
      fileText,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _isWebViewInitialized
            ? Webview(webviewController) // Affichez la WebView une fois initialisée
            : const Center(child: CircularProgressIndicator()), // Affichez un indicateur de chargement
      ),
    );
  }
}