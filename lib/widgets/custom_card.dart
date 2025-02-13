import 'package:flutter/material.dart';
import '/screens/ens_pages/gestion_classe_eleve.dart';
import '/screens/ens_pages/gestion_classe_matiere.dart';


class CustomCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tileColor;
  final Color headerColor;
  final Color color;
  final List<DataColumn>? columns;
  final List<DataRow>? rows;

  const CustomCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tileColor,
    required this.headerColor,
    this.columns,
    this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (columns != null && rows != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  border: TableBorder.all(
                    color: headerColor,
                    borderRadius: BorderRadius.circular(12),
                    width: 2,
                  ),
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      return headerColor;
                    },
                  ),
                  columns: columns!,
                  rows: rows!,
                ),
              ),
            ),
          Container(
            color: tileColor,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: const Icon(
                  Icons.class_,
                  color: Colors.white,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(subtitle),
              trailing: Icon(icon),
              onTap: () {
                if (title == "Gestion des classes et de matières") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionClassesMatieres(),
                    ),
                  );
                  } else if (title == "Gestion des classes et des élèves") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GestionClassesEleves(),
                      ),
                    );
                  }
              },
            ),
          ),
        ],
      ),
    );
  }
}
