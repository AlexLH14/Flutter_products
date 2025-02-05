import 'dart:html' as html; // Solo para web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class ExportExcelButton extends StatelessWidget {
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.file_download), // Icono principal de descarga
      onSelected: (value) async {
        if (value == "xlsx") {
          await _exportToExcel(context);
        } else if (value == "csv") {
          await _exportToCSV(context);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: "xlsx",
            child: Row(
              children: [
                Icon(Icons.insert_chart, color: Colors.green),
                SizedBox(width: 8),
                Text("Descargar XLSX"),
              ],
            ),
          ),
          PopupMenuItem(
            value: "csv",
            child: Row(
              children: [
                Icon(Icons.table_chart_outlined,
                    color: Color.fromARGB(255, 27, 224, 132)),
                SizedBox(width: 8),
                Text("Descargar CSV"),
              ],
            ),
          ),
        ];
      },
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      QuerySnapshot snapshot = await products.get();
      var excel = Excel.createExcel();
      var sheet = excel['Productos'];

      var titleStyle = CellStyle(
        bold: true,
        fontSize: 18,
        fontColorHex: "#FFFFFF",
        backgroundColorHex: "#4CAF50",
        horizontalAlign: HorizontalAlign.Center,
      );

      var headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: "#000000",
        backgroundColorHex: "#E0E0E0",
        horizontalAlign: HorizontalAlign.Center,
      );

      var dataStyle = CellStyle(
        fontSize: 12,
        fontColorHex: "#000000",
        horizontalAlign: HorizontalAlign.Left,
      );

      sheet.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("D1"));
      var titleCell = sheet.cell(CellIndex.indexByString("A1"));
      titleCell.value = "Lista de Productos";
      titleCell.cellStyle = titleStyle;

      sheet.appendRow(["Nombre", "Precio", "Descripción", "URL de la Imagen"]);

      for (int i = 0; i < 4; i++) {
        var headerCell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        headerCell.cellStyle = headerStyle;
      }

      snapshot.docs.forEach((doc) {
        final product = doc.data() as Map<String, dynamic>;
        sheet.appendRow([
          product['name'],
          product['price'],
          product['description'],
          product['imageUrl'] ?? 'No disponible'
        ]);
      });

      for (int i = 0; i < snapshot.docs.length; i++) {
        for (int j = 0; j < 4; j++) {
          var dataCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 2));
          dataCell.cellStyle = dataStyle;
        }
      }

      sheet.setColWidth(0, 30);
      sheet.setColWidth(1, 15);
      sheet.setColWidth(2, 40);
      sheet.setColWidth(3, 85);

      var fileBytes = excel.encode();
      if (fileBytes != null) {
        if (kIsWeb) {
          final blob = html.Blob([
            fileBytes
          ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "productos.xlsx")
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/productos.xlsx');
          await file.writeAsBytes(fileBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archivo Excel guardado en: ${file.path}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar a Excel: $e')),
      );
    }
  }

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      QuerySnapshot snapshot = await products.get();
      String csvContent = "Nombre,Precio,Descripción,URL de la Imagen\n";
      snapshot.docs.forEach((doc) {
        final product = doc.data() as Map<String, dynamic>;
        csvContent +=
            '"${product['name']}","${product['price']}","${product['description']}","${product['imageUrl'] ?? 'No disponible'}"\n';
      });

      if (kIsWeb) {
        final bom = utf8.encode('\uFEFF');
        final csvBytes = utf8.encode(csvContent);
        final blob = html.Blob([bom, csvBytes], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "productos.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/productos.csv');
        await file.writeAsString(csvContent, encoding: utf8);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo CSV guardado en: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar a CSV: $e')),
      );
    }
  }
}
