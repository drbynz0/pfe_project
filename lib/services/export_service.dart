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
      logger.e("Erreur lors de l'exportation en PDF: $e");
      DialogService.showDialogMessage(context, "Erreur", "Échec de l'exportation en PDF.");
    }
  }

  static Future<void> exportToExcel(BuildContext context, List<Map<String, dynamic>> students) async {
    try {
      var excel = Excel.createExcel();
      var sheet = excel['Notes'];

      // ✅ Correction : Utilisation de TextCellValue() pour les chaînes
      sheet.appendRow([
        TextCellValue("Code Étudiant"),
        TextCellValue("Nom & Prénom"),
        TextCellValue("Note")
      ]);

      for (var student in students) {
        sheet.appendRow([
          TextCellValue(student["id"]?.toString() ?? "Inconnu"), // Conversion en String
          TextCellValue("${student["nom"] ?? "Inconnu"} ${student["prenom"] ?? "Inconnu"}"),
          TextCellValue(student["note"]?.toString() ?? "-")
        ]);
      }

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/notes.xlsx");
      await file.writeAsBytes(excel.encode()!);

      DialogService.showDialogMessage(context, "Succès", "Excel exporté avec succès !");
    } catch (e) {
      logger.e("Erreur lors de l'exportation en Excel: $e");
      DialogService.showDialogMessage(context, "Erreur", "Échec de l'exportation en Excel.");
    }
  }
}
