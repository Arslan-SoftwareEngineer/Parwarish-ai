import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/therapist_datasheet_model.dart';
import '../../services/therapist_service.dart';
import '../../theme/app_theme.dart';

class DatasheetExportDialog extends StatefulWidget {
  final String childId;
  final String childName;
  final List<DatasheetSessionEntry> entries;

  const DatasheetExportDialog({
    super.key,
    required this.childId,
    required this.childName,
    required this.entries,
  });

  @override
  State<DatasheetExportDialog> createState() => _DatasheetExportDialogState();
}

class _DatasheetExportDialogState extends State<DatasheetExportDialog> {
  int _exportTabIndex = 0;
  String _csvContent = '';
  String _summaryContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepareExportContent();
  }

  Future<void> _prepareExportContent() async {
    final csv = TherapistService.instance.exportDatasheetAsCsv(
      widget.entries,
      childName: widget.childName,
    );

    final summary = await TherapistService.instance.getChildClinicalSummary(
      widget.childId,
      childName: widget.childName,
    );

    final report = TherapistService.instance.generateClinicalSummaryReport(
      summary: summary,
      entries: widget.entries,
      childName: widget.childName,
    );

    setState(() {
      _csvContent = csv;
      _summaryContent = report;
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard! 📋✨'),
        backgroundColor: AppTheme.mintGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
            : Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.greenMintGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.file_download_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Datasheet: ${widget.childName}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '${widget.entries.length} session records ready for clinical reporting',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tab selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _exportTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _exportTabIndex == 0 ? AppTheme.electricBlue : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '📊 Standard CSV',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _exportTabIndex == 0 ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _exportTabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _exportTabIndex == 1 ? AppTheme.electricBlue : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '📄 Case & IEP Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _exportTabIndex == 1 ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Content Preview Box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _exportTabIndex == 0 ? _csvContent : _summaryContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFE2E8F0),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_exportTabIndex == 0) {
                              _copyToClipboard(_csvContent, 'CSV Data');
                            } else {
                              _copyToClipboard(_summaryContent, 'Case Summary');
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, color: Colors.white),
                          label: Text(
                            _exportTabIndex == 0 ? 'Copy CSV Data' : 'Copy Case Summary',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mintGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
