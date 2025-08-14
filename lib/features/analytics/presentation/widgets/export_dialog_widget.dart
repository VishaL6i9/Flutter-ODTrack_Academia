import 'package:flutter/material.dart';
import 'package:odtrack_academia/models/export_models.dart';

/// Dialog widget for configuring analytics export options
class ExportDialogWidget extends StatefulWidget {
  final String title;
  final void Function(ExportFormat format, ExportOptions options) onExport;
  final List<ExportFormat> availableFormats;

  const ExportDialogWidget({
    super.key,
    required this.title,
    required this.onExport,
    this.availableFormats = const [ExportFormat.pdf, ExportFormat.csv],
  });

  @override
  State<ExportDialogWidget> createState() => _ExportDialogWidgetState();
}

class _ExportDialogWidgetState extends State<ExportDialogWidget> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _includeCharts = true;
  bool _includeMetadata = true;
  String _customTitle = '';
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.availableFormats.isNotEmpty) {
      _selectedFormat = widget.availableFormats.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.availableFormats.map((format) => RadioListTile<ExportFormat>(
              title: Text(_getFormatDisplayName(format)),
              subtitle: Text(_getFormatDescription(format)),
              value: format,
              groupValue: _selectedFormat,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
            )),
            
            const SizedBox(height: 16),
            
            // Options section
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Include charts option (only for PDF)
            if (_selectedFormat == ExportFormat.pdf)
              CheckboxListTile(
                title: const Text('Include Charts'),
                subtitle: const Text('Include visual charts in the export'),
                value: _includeCharts,
                onChanged: (value) {
                  setState(() {
                    _includeCharts = value ?? true;
                  });
                },
              ),
            
            // Include metadata option
            CheckboxListTile(
              title: const Text('Include Metadata'),
              subtitle: const Text('Include generation date and filter information'),
              value: _includeMetadata,
              onChanged: (value) {
                setState(() {
                  _includeMetadata = value ?? true;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Custom title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Custom Title (Optional)',
                hintText: 'Enter a custom title for the report',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _customTitle = value;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleExport,
          child: const Text('Export'),
        ),
      ],
    );
  }

  String _getFormatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF Document';
      case ExportFormat.csv:
        return 'CSV Spreadsheet';
      case ExportFormat.excel:
        return 'Excel Workbook';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'Formatted document with charts and styling';
      case ExportFormat.csv:
        return 'Raw data in comma-separated values format';
      case ExportFormat.excel:
        return 'Spreadsheet with multiple sheets and formatting';
    }
  }

  void _handleExport() {
    final options = ExportOptions(
      format: _selectedFormat,
      includeCharts: _includeCharts,
      includeMetadata: _includeMetadata,
      customTitle: _customTitle.isNotEmpty ? _customTitle : null,
    );

    Navigator.of(context).pop();
    widget.onExport(_selectedFormat, options);
  }
}