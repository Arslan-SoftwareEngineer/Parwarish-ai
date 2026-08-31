import 'package:flutter/material.dart';
import '../../models/therapist_datasheet_model.dart';
import '../../models/therapist_domain_model.dart';
import '../../services/therapist_service.dart';
import '../../theme/app_theme.dart';

class NewSessionEntryDialog extends StatefulWidget {
  final String childId;
  final String childName;
  final DatasheetSessionEntry? existingEntry;

  const NewSessionEntryDialog({
    super.key,
    required this.childId,
    required this.childName,
    this.existingEntry,
  });

  @override
  State<NewSessionEntryDialog> createState() => _NewSessionEntryDialogState();
}

class _NewSessionEntryDialogState extends State<NewSessionEntryDialog> {
  late String _sessionType;
  late String _promptLevel;
  late String _sensoryState;
  late int _trialsAttempted;
  late int _trialsSuccessful;

  late TherapistDomainModel _selectedDomain;
  late TherapistGoalModel _selectedGoal;

  late TextEditingController _behaviorController;
  late TextEditingController _clinicalNotesController;
  late TextEditingController _homeRecController;
  late TextEditingController _nextTargetsController;

  final List<String> _sessionTypes = [
    'ABA Therapy',
    'Speech & Language',
    'Occupational Therapy',
    'Social Skills',
    'Baseline Assessment',
  ];

  final List<String> _promptLevels = [
    'Independent',
    'Gestural',
    'Verbal',
    'Modeling',
    'Partial Physical',
    'Full Physical',
  ];

  final List<String> _sensoryStates = [
    'Regulated',
    'Hypersensitive',
    'Hyposensitive',
    'Sensory Seeking',
    'Fatigued',
  ];

  @override
  void initState() {
    super.initState();
    final domains = TherapistService.instance.domains;
    final entry = widget.existingEntry;

    if (entry != null) {
      _sessionType = entry.sessionType;
      _promptLevel = entry.promptLevel;
      _sensoryState = entry.sensoryState;
      _trialsAttempted = entry.trialsAttempted;
      _trialsSuccessful = entry.trialsSuccessful;

      _selectedDomain = domains.firstWhere(
        (d) => d.id == entry.domainId,
        orElse: () => domains.first,
      );
      _selectedGoal = _selectedDomain.goals.firstWhere(
        (g) => g.id == entry.goalId,
        orElse: () => _selectedDomain.goals.first,
      );

      _behaviorController = TextEditingController(text: entry.behavioralNotes);
      _clinicalNotesController = TextEditingController(text: entry.clinicalNotes);
      _homeRecController = TextEditingController(text: entry.homeRecommendations);
      _nextTargetsController = TextEditingController(text: entry.nextSessionTargets);
    } else {
      _sessionType = 'ABA Therapy';
      _promptLevel = 'Gestural';
      _sensoryState = 'Regulated';
      _trialsAttempted = 10;
      _trialsSuccessful = 8;

      _selectedDomain = domains.first;
      _selectedGoal = _selectedDomain.goals.first;

      _behaviorController = TextEditingController(text: 'High engagement. Promptly transitioned with visual timer cue.');
      _clinicalNotesController = TextEditingController(text: 'Demonstrated steady accuracy. Prompt faded on the last 3 trials.');
      _homeRecController = TextEditingController(text: 'Reinforce target skill at home with positive descriptive praise.');
      _nextTargetsController = TextEditingController(text: 'Aim for 90%+ independent mastery next session.');
    }
  }

  @override
  void dispose() {
    _behaviorController.dispose();
    _clinicalNotesController.dispose();
    _homeRecController.dispose();
    _nextTargetsController.dispose();
    super.dispose();
  }

  double get _masteryScore {
    if (_trialsAttempted <= 0) return 0.0;
    return (_trialsSuccessful / _trialsAttempted) * 100;
  }

  void _onDomainChanged(TherapistDomainModel? domain) {
    if (domain == null) return;
    setState(() {
      _selectedDomain = domain;
      _selectedGoal = domain.goals.first;
    });
  }

  void _saveEntry() {
    final entry = DatasheetSessionEntry.create(
      id: widget.existingEntry?.id ?? 'ds_${DateTime.now().millisecondsSinceEpoch}',
      childId: widget.childId,
      childName: widget.childName,
      date: widget.existingEntry?.date ?? DateTime.now(),
      sessionType: _sessionType,
      domainId: _selectedDomain.id,
      domainTitle: _selectedDomain.titleEn,
      goalId: _selectedGoal.id,
      goalTitle: _selectedGoal.titleEn,
      promptLevel: _promptLevel,
      trialsAttempted: _trialsAttempted,
      trialsSuccessful: _trialsSuccessful,
      sensoryState: _sensoryState,
      behavioralNotes: _behaviorController.text.trim(),
      clinicalNotes: _clinicalNotesController.text.trim(),
      homeRecommendations: _homeRecController.text.trim(),
      nextSessionTargets: _nextTargetsController.text.trim(),
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final domains = TherapistService.instance.domains;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.blueCyanGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.note_alt_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existingEntry == null ? 'Log Clinical Session Entry' : 'Edit Session Entry',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Child: ${widget.childName}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
            const Divider(height: 24),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Type Picker
                    const Text('Session Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sessionType,
                          isExpanded: true,
                          items: _sessionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _sessionType = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clinical Domain
                    const Text('Target Clinical Domain (22 Domains):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TherapistDomainModel>(
                          value: _selectedDomain,
                          isExpanded: true,
                          items: domains.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('#${d.indexNumber} ${d.titleEn}', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: _onDomainChanged,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clinical Goal
                    const Text('Specific Clinical Objective / IEP Target:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TherapistGoalModel>(
                          value: _selectedGoal,
                          isExpanded: true,
                          items: _selectedDomain.goals.map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.titleEn, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (goal) {
                            if (goal != null) setState(() => _selectedGoal = goal);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Prompt Level Hierarchy Selector
                    const Text('Prompt Hierarchy Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _promptLevels.map((p) {
                        final isSel = _promptLevel == p;
                        return ChoiceChip(
                          label: Text(p, style: TextStyle(color: isSel ? Colors.white : AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: AppTheme.purpleStart,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? AppTheme.purpleStart : const Color(0xFFE2E8F0)),
                          onSelected: (_) => setState(() => _promptLevel = p),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Trials & Mastery Live Calculation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trials Attempted:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryOrange),
                                    onPressed: _trialsAttempted > 1
                                        ? () {
                                            setState(() {
                                              _trialsAttempted--;
                                              if (_trialsSuccessful > _trialsAttempted) {
                                                _trialsSuccessful = _trialsAttempted;
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  Text('$_trialsAttempted', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryOrange),
                                    onPressed: () => setState(() => _trialsAttempted++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Successful / Independent:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.mintGreen),
                                    onPressed: _trialsSuccessful > 0
                                        ? () => setState(() => _trialsSuccessful--)
                                        : null,
                                  ),
                                  Text('$_trialsSuccessful', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.mintGreen)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.mintGreen),
                                    onPressed: _trialsSuccessful < _trialsAttempted
                                        ? () => setState(() => _trialsSuccessful++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calculated Mastery Rate:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _masteryScore >= 80
                                      ? AppTheme.mintGreen.withValues(alpha: 0.15)
                                      : (_masteryScore >= 50 ? Colors.amber.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_masteryScore.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _masteryScore >= 80 ? AppTheme.mintGreen : (_masteryScore >= 50 ? Colors.orange.shade800 : Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sensory State Chips
                    const Text('Observed Sensory / Affect State:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sensoryStates.map((s) {
                        final isSel = _sensoryState == s;
                        return ChoiceChip(
                          label: Text(s, style: TextStyle(color: isSel ? Colors.white : AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: AppTheme.electricBlue,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? AppTheme.electricBlue : const Color(0xFFE2E8F0)),
                          onSelected: (_) => setState(() => _sensoryState = s),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Behavioral Notes (ABC)
                    const Text('Behavioral Observations (ABC Log):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _behaviorController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Antecedent, behavior, and consequence notes...'),
                    ),

                    const SizedBox(height: 16),

                    // Clinical Notes
                    const Text('Clinical Notes & Qualitative Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _clinicalNotesController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Therapist clinical observations, prompting nuances...'),
                    ),

                    const SizedBox(height: 16),

                    // Home Recommendations
                    const Text('Home Recommendations for Parents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _homeRecController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Specific suggestions for home practice...'),
                    ),

                    const SizedBox(height: 16),

                    // Next Session Targets
                    const Text('Next Session Targets & Adjustments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nextTargetsController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Planned fading steps or new target criteria...'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveEntry,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(
                      widget.existingEntry == null ? 'Save Session Entry' : 'Update Entry',
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
