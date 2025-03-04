import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html; // Importer dart:html pour manipuler les éléments web

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Enregistrer l'élément HTML pour afficher la page web
    // Note: ui.platformViewRegistry est disponible uniquement pour Flutter Web
    ui_web.platformViewRegistry.registerViewFactory(
      'admin-login',
      (int viewId) => html.IFrameElement()
        ..src = 'index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const HtmlElementView(viewType: 'admin-login'),
      ),
    );
  }
}
