import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../features/orders/models/sales_order.dart';

class PdfExportService {
  static Future<void> printOrExportSalesOrder(SalesOrder order) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange700,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'HPF',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'HULIOT PIPES & FITTINGS',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'SALES ORDER / ESTIMATE',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'SO No: ${order.salesOrderNo}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date: ${dateFormat.format(order.orderDate)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    if (order.poNo.isNotEmpty)
                      pw.Text(
                        'PO/Ref: ${order.poNo}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Huliot India Pvt. Ltd. | Confidential Sales Order Document',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),
            // Customer & Address Info Grid
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Info
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        if (order.customerName.isNotEmpty) pw.Text('Name: ${order.customerName}', style: const pw.TextStyle(fontSize: 9)),
                        if (order.customerCode.isNotEmpty) pw.Text('Code: ${order.customerCode}', style: const pw.TextStyle(fontSize: 9)),
                        if (order.contactPerson.isNotEmpty) pw.Text('Contact: ${order.contactPerson}', style: const pw.TextStyle(fontSize: 9)),
                        if (order.phone.isNotEmpty || order.mobile.isNotEmpty)
                          pw.Text('Phone: ${order.phone.isNotEmpty ? order.phone : order.mobile}', style: const pw.TextStyle(fontSize: 9)),
                        if (order.projectName.isNotEmpty) pw.Text('Project: ${order.projectName}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Bill To
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO ADDRESS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('${order.bill1} ${order.bill2}'.trim(), style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('${order.billCity}, ${order.billProvince} ${order.billZip}'.trim(), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Ship To
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIP TO ADDRESS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('${order.ship1} ${order.ship2}'.trim(), style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('${order.shipCity}, ${order.shipProvince} ${order.shipZip}'.trim(), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            // Terms info
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: PdfColors.grey100,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Salesperson: ${order.salesPerson.isEmpty ? "N/A" : order.salesPerson}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Payment Terms: ${order.paymentTerms}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Delivery Terms: ${order.deliveryTerm}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Required Date: ${dateFormat.format(order.requiredDate)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(35),
                3: const pw.FixedColumnWidth(30),
                4: const pw.FixedColumnWidth(55),
                5: const pw.FixedColumnWidth(35),
                6: const pw.FixedColumnWidth(55),
                7: const pw.FixedColumnWidth(65),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _th('#'),
                    _th('ITEM / DESCRIPTION'),
                    _th('DN'),
                    _th('QTY'),
                    _th('LIST PR.'),
                    _th('DISC%'),
                    _th('NET PR.'),
                    _th('AMOUNT'),
                  ],
                ),
                // Rows
                ...order.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _td('$idx', align: pw.TextAlign.center),
                      _td('${item.itemCode}\n${item.description}'),
                      _td(item.dn?.toString() ?? '-', align: pw.TextAlign.center),
                      _td('${item.qty}', align: pw.TextAlign.center),
                      _td(currencyFormat.format(item.listPrice), align: pw.TextAlign.right),
                      _td('${(item.discount * 100).round()}%', align: pw.TextAlign.center),
                      _td(currencyFormat.format(item.unitPrice), align: pw.TextAlign.right),
                      _td(currencyFormat.format(item.amount), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            // Summary Calculation box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Remarks
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('REMARKS & INSTRUCTIONS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(order.remarks, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                // Totals
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    children: [
                      _totalRow('Total Quantity:', '${order.totalQty} pcs'),
                      pw.Divider(color: PdfColors.grey300, height: 8),
                      _totalRow('Subtotal:', currencyFormat.format(order.subtotal)),
                      _totalRow('GST (18%):', currencyFormat.format(order.gst)),
                      pw.Divider(color: PdfColors.grey400, height: 8),
                      _totalRow(
                        'Grand Total:',
                        currencyFormat.format(order.grandTotal),
                        isBold: true,
                        color: PdfColors.orange800,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${order.salesOrderNo}_Huliot_SalesOrder.pdf',
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool isBold = false, PdfColor? color, double fontSize = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
