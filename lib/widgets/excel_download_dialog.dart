import 'package:flutter/material.dart';

/// Shows a dialog allowing the user to view and edit the filename before downloading Excel.
Future<String?> showExcelExportDialog(
  BuildContext context, {
  required String defaultFileName,
}) async {
  final controller = TextEditingController(text: defaultFileName);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(
                Icons.table_view_rounded,
                color: Color(0xFF059669),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Excel Workbook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Edit file name before downloading',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'File Name',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  suffixText: '.xlsx',
                  suffixStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a file name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop(controller.text.trim());
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      );
    },
  );
}
