import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../models/therapist_datasheet_model.dart';
import '../../services/therapist_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';
import 'new_session_entry_dialog.dart';
import 'child_clinical_profile_modal.dart';
import 'datasheet_export_dialog.dart';

class DatasheetTableView extends StatefulWidget {
  final ChildModel child;

  const DatasheetTableView({
    super.key,
    required this.child,
  });

  @override
  State<DatasheetTableView> createState() => _DatasheetTableViewState();
}

class _DatasheetTableViewState extends State<DatasheetTableView> {
  List<DatasheetSessionEntry> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDomainFilter = 'All';
  String _selectedSessionTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadDatasheet();
  }

  @override
  void didUpdateWidget(covariant DatasheetTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.id != widget.child.id) {
      _loadDatasheet();
    }
  }

  Future<void> _loadDatasheet() async {
    setState(() => _isLoading = true);
    final list = await TherapistService.instance.getDatasheetEntriesForChild(
      widget.child.id,
      childName: widget.child.name,
    );
    setState(() {
      _entries = list;
      _isLoading = false;
    });
  }

  Future<void> _openNewEntryDialog([DatasheetSessionEntry? existing]) async {
    final result = await showDialog<DatasheetSessionEntry>(
      context: context,
      builder: (_) => NewSessionEntryDialog(
        childId: widget.child.id,
        childName: widget.child.name,
        existingEntry: existing,
      ),
    );

    if (result != null) {
      await TherapistService.instance.saveDatasheetEntry(result);
      await _loadDatasheet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing == null ? 'Session entry logged! 📝' : 'Session entry updated! ✨'),
            backgroundColor: AppTheme.mintGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(DatasheetSessionEntry entry) async {
    final tr = LocalizationService.instance.tr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('delete_entry')),
        content: Text(tr('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TherapistService.instance.deleteDatasheetEntry(widget.child.id, entry.id);
      await _loadDatasheet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session entry deleted.')),
        );
      }
    }
  }

  void _openClinicalProfile() {
    showDialog(
      context: context,
      builder: (_) => ChildClinicalProfileModal(
        childId: widget.child.id,
        childName: widget.child.name,
      ),
    );
  }

  void _openExportDialog() {
    showDialog(
      context: context,
      builder: (_) => DatasheetExportDialog(
        childId: widget.child.id,
        childName: widget.child.name,
        entries: _filteredEntries,
      ),
    );
  }

  List<DatasheetSessionEntry> get _filteredEntries {
    return _entries.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.goalTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.domainTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.clinicalNotes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.behavioralNotes.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesDomain = _selectedDomainFilter == 'All' || e.domainId == _selectedDomainFilter;
      final matchesType = _selectedSessionTypeFilter == 'All' || e.sessionType == _selectedSessionTypeFilter;

      return matchesSearch && matchesDomain && matchesType;
    }).toList();
  }

  double get _averageMastery {
    if (_entries.isEmpty) return 0.0;
    final sum = _entries.fold<double>(0.0, (prev, e) => prev + e.masteryPercentage);
    return sum / _entries.length;
  }

  @override
  Widget build(BuildContext context) {
    final tr = LocalizationService.instance.tr;
    final domains = TherapistService.instance.domains;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.purpleBlueGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.purpleStart),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.table_chart_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.child.name}\'s Clinical Datasheet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level: ${widget.child.autismLevel}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr('datasheet_subtitle'),
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),

                // Quick Clinical Metric Chips
                Row(
                  children: [
                    _buildStatPill('Total Sessions', '${_entries.length}', Icons.event_note_rounded),
                    const SizedBox(width: 8),
                    _buildStatPill('Avg Mastery', '${_averageMastery.toStringAsFixed(0)}%', Icons.verified_rounded),
                    const SizedBox(width: 8),
                    _buildStatPill('Streak', '${widget.child.currentStreak}d', Icons.local_fire_department_rounded),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Toolbar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openNewEntryDialog(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text(tr('new_session_entry'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openClinicalProfile,
                icon: const Icon(Icons.badge_rounded, color: AppTheme.purpleStart, size: 18),
                label: Text(tr('clinical_profile'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purpleStart)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  side: const BorderSide(color: AppTheme.purpleStart),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openExportDialog,
                icon: const Icon(Icons.file_download_rounded, color: AppTheme.electricBlue, size: 18),
                label: Text(tr('export_data'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  side: const BorderSide(color: AppTheme.electricBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search and Filters Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: tr('search_records'),
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.electricBlue, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDomainFilter,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            items: [
                              const DropdownMenuItem(value: 'All', child: Text('All Domains', style: TextStyle(fontSize: 12))),
                              ...domains.map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text('#${d.indexNumber} ${d.titleEn}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDomainFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSessionTypeFilter,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Session Types', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'ABA Therapy', child: Text('ABA Therapy', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Speech & Language', child: Text('Speech & Language', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Occupational Therapy', child: Text('Occupational Therapy', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Social Skills', child: Text('Social Skills', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Baseline Assessment', child: Text('Baseline Assessment', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSessionTypeFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Entries List
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.electricBlue),
            ))
          else if (_filteredEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                children: [
                  const Icon(Icons.content_paste_off_rounded, color: AppTheme.textLight, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No session records found matching the criteria.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openNewEntryDialog(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue),
                    child: const Text('Log First Session Entry'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEntries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return _buildDatasheetCard(entry);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasheetCard(DatasheetSessionEntry entry) {
    final dateStr = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
    final isHighMastery = entry.masteryPercentage >= 80;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softCardShadow,
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date, Session Type, & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.electricBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.sessionType,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleStart),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryOrange),
                    tooltip: 'Edit Record',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openNewEntryDialog(entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    tooltip: 'Delete Record',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteEntry(entry),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Goal & Domain
          Text(
            entry.goalTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            entry.domainTitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 12),

          // Metrics Row
          Row(
            children: [
              // Prompt Level
              _buildMetricChip(
                label: 'Prompt',
                value: entry.promptLevel,
                color: _getPromptColor(entry.promptLevel),
              ),
              const SizedBox(width: 8),
              // Trials & Mastery
              _buildMetricChip(
                label: 'Trials',
                value: '${entry.trialsSuccessful}/${entry.trialsAttempted} (${entry.masteryPercentage}%)',
                color: isHighMastery ? AppTheme.mintGreen : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              // Sensory State
              _buildMetricChip(
                label: 'Sensory',
                value: entry.sensoryState,
                color: AppTheme.electricBlue,
              ),
            ],
          ),

          if (entry.clinicalNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Therapist Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.clinicalNotes,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPromptColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('independent')) return AppTheme.mintGreen;
    if (l.contains('gestural')) return AppTheme.purpleStart;
    if (l.contains('verbal')) return AppTheme.electricBlue;
    if (l.contains('modeling')) return AppTheme.primaryOrange;
    return Colors.redAccent;
  }
}
