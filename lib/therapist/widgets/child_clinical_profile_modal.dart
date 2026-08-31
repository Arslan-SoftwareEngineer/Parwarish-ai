import 'package:flutter/material.dart';
import '../../models/therapist_datasheet_model.dart';
import '../../services/therapist_service.dart';
import '../../theme/app_theme.dart';

class ChildClinicalProfileModal extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildClinicalProfileModal({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildClinicalProfileModal> createState() => _ChildClinicalProfileModalState();
}

class _ChildClinicalProfileModalState extends State<ChildClinicalProfileModal> {
  bool _isLoading = true;

  late TextEditingController _caseIdController;
  late TextEditingController _therapistController;
  late TextEditingController _diagnosisController;
  late TextEditingController _triggersController;
  late TextEditingController _reinforcersController;
  late TextEditingController _modalitiesController;
  late TextEditingController _bipController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final summary = await TherapistService.instance.getChildClinicalSummary(
      widget.childId,
      childName: widget.childName,
    );

    setState(() {
      _caseIdController = TextEditingController(text: summary.caseId);
      _therapistController = TextEditingController(text: summary.primaryTherapist);
      _diagnosisController = TextEditingController(text: summary.diagnosisSummary);
      _triggersController = TextEditingController(text: summary.sensoryTriggers.join(', '));
      _reinforcersController = TextEditingController(text: summary.primaryReinforcers.join(', '));
      _modalitiesController = TextEditingController(text: summary.communicationModalities.join(', '));
      _bipController = TextEditingController(text: summary.targetBehaviorPlan);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _caseIdController.dispose();
      _therapistController.dispose();
      _diagnosisController.dispose();
      _triggersController.dispose();
      _reinforcersController.dispose();
      _modalitiesController.dispose();
      _bipController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final updated = ChildClinicalSummary(
      childId: widget.childId,
      caseId: _caseIdController.text.trim(),
      primaryTherapist: _therapistController.text.trim(),
      diagnosisSummary: _diagnosisController.text.trim(),
      sensoryTriggers: _triggersController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      primaryReinforcers: _reinforcersController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      communicationModalities: _modalitiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      targetBehaviorPlan: _bipController.text.trim(),
      lastUpdated: DateTime.now(),
    );

    await TherapistService.instance.saveChildClinicalSummary(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clinical Case Profile updated for ${widget.childName}! ✨'),
          backgroundColor: AppTheme.mintGreen,
        ),
      );
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
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
                          gradient: AppTheme.purpleBlueGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Case Profile: ${widget.childName}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const Text(
                              'Therapist-managed IEP & sensory support baseline',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Case ID / Medical Record #:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(controller: _caseIdController),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Primary Clinical BCBA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(controller: _therapistController),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text('Clinical Diagnosis & Therapy Focus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _diagnosisController,
                            maxLines: 2,
                            decoration: const InputDecoration(hintText: 'e.g., ASD Profile, Joint Attention & Speech Delay...'),
                          ),

                          const SizedBox(height: 16),

                          const Text('Sensory Triggers / Sensitivities (comma-separated):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _triggersController,
                            maxLines: 2,
                            decoration: const InputDecoration(hintText: 'e.g., Sudden loud noises, Bright flickering lights...'),
                          ),

                          const SizedBox(height: 16),

                          const Text('Primary Reinforcers & Preferences (comma-separated):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _reinforcersController,
                            maxLines: 2,
                            decoration: const InputDecoration(hintText: 'e.g., Star badges, Sensory chime sound, High-fives...'),
                          ),

                          const SizedBox(height: 16),

                          const Text('Communication Modalities (comma-separated):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _modalitiesController,
                            decoration: const InputDecoration(hintText: 'e.g., Verbal mands, Visual PECS, Interactive touch...'),
                          ),

                          const SizedBox(height: 16),

                          const Text('Behavior Intervention Plan (BIP) Highlights:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _bipController,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Transition countdown timers, differential reinforcement of alternative behavior...'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save_rounded, color: Colors.white),
                          label: const Text('Save Case Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.purpleStart,
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
