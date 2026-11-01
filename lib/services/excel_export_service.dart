import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../features/orders/models/sales_order.dart';

/// Populates the "SO FORMAT PROJECT - APRIL 2026.xlsx" template
/// with exact cell positions and original styling, then downloads
/// the complete workbook with all formulas, styles, and sheets preserved.
class ExcelExportService {
  static final _dateFormat = DateFormat('dd-MMM-yyyy');

  static String getDefaultFileName(SalesOrder order) {
    final soNo = order.salesOrderNo.isNotEmpty
        ? order.salesOrderNo
        : 'SO-${DateFormat('yyyyMMdd').format(DateTime.now())}';
    return 'SO FORMAT PROJECT - APRIL 2026 ($soNo)';
  }

  static Future<bool> generateAndDownloadExcel(
    SalesOrder order, {
    String? customFileName,
  }) async {
    if (order.items.isEmpty) {
      throw Exception(
          'Please add at least one item from Catalog before downloading Excel.');
    }
    if (order.items.length > 75) {
      throw Exception(
          'The SO FORMAT template supports up to 75 item rows. Current items: ${order.items.length}.');
    }

    try {
      // Load the exact user-supplied template
      final ByteData templateData =
          await rootBundle.load('assets/data/so_template.xlsx');
      final Uint8List bytes = templateData.buffer.asUint8List();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      // Sales Order is Sheet 2 (rId2 -> sheet2.xml per workbook.xml.rels)
      const salesOrderPath = 'xl/worksheets/sheet2.xml';
      final sheetFile = archive.findFile(salesOrderPath);
      if (sheetFile == null) {
        throw Exception('Template worksheet sheet2.xml not found');
      }

      String xml = utf8.decode(sheetFile.content as List<int>);

      // Helpers
      String escXml(dynamic v) {
        return (v?.toString() ?? '')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&apos;');
      }

      // Safe cell replacement that distinguishes self-closing tags from full tags
      // to avoid accidentally matching into adjacent cells.
      String replaceCell(String xmlText, String ref, String replacement) {
        final pattern = RegExp(
            '<c [^>]*?r="$ref"[^>]*?\\/>|<c [^>]*?r="$ref"[^>\\/]*?>[\\s\\S]*?<\\/c>');
        if (pattern.hasMatch(xmlText)) {
          return xmlText.replaceFirst(pattern, replacement);
        }

        // Cell doesn't exist, inject it into row
        final rowNum = RegExp(r'(\d+)$').firstMatch(ref)?.group(1) ?? '';
        final rowPattern = RegExp('<row [^>]*?r="$rowNum"[^>]*>');
        final rowMatch = rowPattern.firstMatch(xmlText);
        if (rowMatch != null) {
          final insertPoint = rowMatch.end;
          return xmlText.substring(0, insertPoint) +
              replacement +
              xmlText.substring(insertPoint);
        }
        return xmlText;
      }

      String textCell(String ref, int style, String value) {
        if (value.isEmpty) return '<c r="$ref" s="$style"/>';
        return '<c r="$ref" s="$style" t="inlineStr"><is><t>${escXml(value)}</t></is></c>';
      }

      String numCell(String ref, int style, dynamic value) {
        if (value == null || value.toString().isEmpty) {
          return '<c r="$ref" s="$style"/>';
        }
        final numVal = num.tryParse(value.toString());
        if (numVal == null) return '<c r="$ref" s="$style"/>';
        return '<c r="$ref" s="$style"><v>$numVal</v></c>';
      }

      // ─── Header Fields (Exact Mapped Cell Coordinates) ───────────────────────
      // Row 6: Sales Person (F6), PO No (J6), PO Date (N6)
      xml = replaceCell(xml, 'F6', textCell('F6', 151, order.salesPerson));
      xml = replaceCell(xml, 'J6', textCell('J6', 5, order.poNo));
      xml = replaceCell(
          xml, 'N6', textCell('N6', 6, _dateFormat.format(order.orderDate)));

      // Row 8: Customer PO No (C8), Sales Order No (J8), Date (N8)
      xml = replaceCell(xml, 'C8', textCell('C8', 4, order.poNo));
      xml = replaceCell(xml, 'J8', textCell('J8', 5, order.salesOrderNo));
      xml = replaceCell(
          xml, 'N8', textCell('N8', 6, _dateFormat.format(order.orderDate)));

      // Row 9: Contact Person (J9), Mobile (N9)
      xml = replaceCell(xml, 'J9', textCell('J9', 5, order.contactPerson));
      xml = replaceCell(xml, 'N9', textCell('N9', 87, order.mobile));

      // Row 11: Bill To Name (B11), Ship To Name (I11)
      xml = replaceCell(xml, 'B11', textCell('B11', 36, order.customerName));
      xml = replaceCell(xml, 'I11', textCell('I11', 38, order.customerName));

      // Row 12: Bill Address (B12), Ship Address (I12)
      final billAddr =
          [order.bill1, order.bill2].where((s) => s.isNotEmpty).join(', ');
      final shipAddr =
          [order.ship1, order.ship2].where((s) => s.isNotEmpty).join(', ');
      xml = replaceCell(xml, 'B12', textCell('B12', 37, billAddr));
      xml = replaceCell(xml, 'I12', textCell('I12', 41, shipAddr));

      // Row 14: Bill City (B14), Ship City (I14)
      xml = replaceCell(xml, 'B14', textCell('B14', 67, order.billCity));
      xml = replaceCell(xml, 'I14', textCell('I14', 41, order.shipCity));

      // Row 15: Bill Pin (B15), Ship Pin (I15)
      xml = replaceCell(xml, 'B15', textCell('B15', 67, order.billZip));
      xml = replaceCell(xml, 'I15', textCell('I15', 41, order.shipZip));

      // Row 16: Bill GSTIN (B16), Ship GSTIN (I16)
      xml = replaceCell(xml, 'B16', textCell('B16', 70, ''));
      xml = replaceCell(xml, 'I16', textCell('I16', 44, ''));

      // Row 18: Term of Delivery (C18)
      xml = replaceCell(xml, 'C18', textCell('C18', 47, order.deliveryTerm));

      // Row 19: Payment Term (C19) - Note: C17 cash discount formula checks C19!
      xml = replaceCell(xml, 'C19', textCell('C19', 47, order.paymentTerms));

      // Row 20: Consultant Firm (D20), Contact No (K20)
      xml = replaceCell(xml, 'D20', textCell('D20', 185, ''));
      xml = replaceCell(xml, 'K20', textCell('K20', 191, order.phone));

      // Row 21: Developer Name (D21), Site/Project Name (K21)
      xml = replaceCell(xml, 'D21', textCell('D21', 194, order.customerName));
      xml = replaceCell(xml, 'K21', textCell('K21', 200, order.projectName));

      // Row 22: Other Remarks (C22)
      xml = replaceCell(xml, 'C22', textCell('C22', 204, order.remarks));

      // ─── Line Items (Rows 25 to 99) ──────────────────────────────────────────
      // B = Material No (s=95), G = Order Qty (s=51), J = Discount % (s=78)
      // Unused rows must remain clean empty cells to preserve VLOOKUP & IF formulas.
      for (int r = 25; r <= 99; r++) {
        final idx = r - 25;
        if (idx < order.items.length) {
          final it = order.items[idx];
          double disc = it.discount;
          if (disc > 1) disc = disc / 100.0;

          xml = replaceCell(xml, 'B$r', textCell('B$r', 95, it.itemCode));
          xml = replaceCell(xml, 'G$r', numCell('G$r', 51, it.qty));
          xml = replaceCell(xml, 'J$r', numCell('J$r', 78, disc));
        } else {
          xml = replaceCell(xml, 'B$r', '<c r="B$r" s="95"/>');
          xml = replaceCell(xml, 'G$r', '<c r="G$r" s="51"/>');
          xml = replaceCell(xml, 'J$r', '<c r="J$r" s="78"/>');
        }
      }

      // ─── Rebuild Archive Safely ──────────────────────────────────────────────
      final updatedSheetBytes = utf8.encode(xml);

      Uint8List? updatedWbBytes;
      final wbFile = archive.findFile('xl/workbook.xml');
      if (wbFile != null) {
        String wb = utf8.decode(wbFile.content as List<int>);
        if (wb.contains('<calcPr')) {
          wb = wb.replaceAll(
              RegExp(r'<calcPr[^>]*\/>'),
              '<calcPr calcId="0" fullCalcOnLoad="1" forceFullCalc="1"/>');
        } else {
          wb = wb.replaceFirst('</workbook>',
              '<calcPr calcId="0" fullCalcOnLoad="1" forceFullCalc="1"/></workbook>');
        }
        updatedWbBytes = Uint8List.fromList(utf8.encode(wb));
      }

      Uint8List? updatedTypesBytes;
      final typesFile = archive.findFile('[Content_Types].xml');
      if (typesFile != null) {
        String types = utf8.decode(typesFile.content as List<int>);
        types = types.replaceAll(
            RegExp(r'<Override[^>]*calcChain\.xml[^>]*\/>'), '');
        updatedTypesBytes = Uint8List.fromList(utf8.encode(types));
      }

      Uint8List? updatedRelsBytes;
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (relsFile != null) {
        String rels = utf8.decode(relsFile.content as List<int>);
        rels = rels.replaceAll(
            RegExp(r'<Relationship[^>]*calcChain[^>]*\/>'), '');
        updatedRelsBytes = Uint8List.fromList(utf8.encode(rels));
      }

      // Construct a new archive safely without mutating unmodifiable lists
      final newArchive = Archive();
      for (final file in archive.files) {
        if (file.name == 'xl/calcChain.xml') continue;

        if (file.name == salesOrderPath) {
          newArchive.addFile(ArchiveFile(
              salesOrderPath, updatedSheetBytes.length, updatedSheetBytes));
        } else if (file.name == 'xl/workbook.xml' && updatedWbBytes != null) {
          newArchive.addFile(ArchiveFile(
              'xl/workbook.xml', updatedWbBytes.length, updatedWbBytes));
        } else if (file.name == '[Content_Types].xml' &&
            updatedTypesBytes != null) {
          newArchive.addFile(ArchiveFile('[Content_Types].xml',
              updatedTypesBytes.length, updatedTypesBytes));
        } else if (file.name == 'xl/_rels/workbook.xml.rels' &&
            updatedRelsBytes != null) {
          newArchive.addFile(ArchiveFile('xl/_rels/workbook.xml.rels',
              updatedRelsBytes.length, updatedRelsBytes));
        } else {
          newArchive.addFile(file);
        }
      }

      // ─── Encode & Download ───────────────────────────────────────────────────
      final List<int>? encodedZip = ZipEncoder().encode(newArchive);
      if (encodedZip == null) {
        throw Exception('Failed to encode Excel zip output');
      }

      final Uint8List outputBytes = Uint8List.fromList(encodedZip);
      final soNo = order.salesOrderNo.isNotEmpty
          ? order.salesOrderNo
          : 'SO-${DateTime.now().millisecondsSinceEpoch}';
      String fileName = customFileName?.trim().isNotEmpty == true
          ? customFileName!.trim()
          : 'SO FORMAT PROJECT - APRIL 2026 ($soNo)';
      if (fileName.toLowerCase().endsWith('.xlsx')) {
        fileName = fileName.substring(0, fileName.length - 5);
      }

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: outputBytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
