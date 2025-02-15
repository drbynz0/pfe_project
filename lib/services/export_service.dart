// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '/services/dialog_service.dart';

// ✅ Instanciation du logger
final Logger logger = Logger();

class ExportService {
  static Future<void> exportToPDF(BuildContext context, List<Map<String, dynamic>> students) async {
    try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.TableHelper.fromTextArray(
            headers: ["Code Étudiant", "Nom & Prénom", "Note"],
            data: students.map((student) => [
              student["id"],
              "${student["nom"]} ${student["prenom"]}",
              student["note"].isEmpty ? "-" : student["note"]
            ]).toList(),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/notes.pdf");
    await file.writeAsBytes(await pdf.save());

    DialogService.showDialogMessage(context, "Succès", "PDF exporté avec succès !");
    } catch (e) {
      DialogService.showDialogMessage(context, "Erreur", "Échec de l'exportation en PDF.");
    }

  }

  static Future<void> exportToExcel(BuildContext context, List<Map<String, dynamic>> students) async {
    try {
    var excel = Excel.createExcel();
    var sheet = excel['Notes'];

    sheet.appendRow(["Code Étudiant", "Nom & Prénom", "Note"]);

    for (var student in students) {
      sheet.appendRow([
        student["id"],
        "${student["nom"]} ${student["prenom"]}",
        student["note"].isEmpty ? "-" : student["note"]
      ]);
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/notes.xlsx");
    await file.writeAsBytes(excel.encode()!);

    DialogService.showDialogMessage(context, "Succès", "Excel exporté avec succès !");
    } catch (e) {
      DialogService.showDialogMessage(context, "Erreur", "Échec de l'exportation en Excel.");
    }

 }
}
