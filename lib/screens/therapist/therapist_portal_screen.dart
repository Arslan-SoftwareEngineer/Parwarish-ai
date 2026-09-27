import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/clinical_service.dart';
import '../../models/child_profile.dart';
import '../../models/daily_session_model.dart';
import '../../core/constants/clinical_domains.dart';
import 'therapist_login_screen.dart';

class TherapistPortalScreen extends StatefulWidget {
  final int initialTabIndex;
  const TherapistPortalScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TherapistPortalScreen> createState() => _TherapistPortalScreenState();
}

class _TherapistPortalScreenState extends State<TherapistPortalScreen> {
  int _activeNavIndex = 0;
  List<ChildProfile> _children = [];
  ChildProfile? _selectedChild;
  String _selectedDate = _formatDate(DateTime.now());
  DailySessionModel? _currentSession;
  bool _isLoading = true;

  // Search filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Studio Domain filter
  int _selectedDomainId = 1;
  final Set<String> _pendingGoalIds = {};

  // Report Generator Form Controllers
  final _reportObservationsController = TextEditingController();
  final _reportStrengthsController = TextEditingController();
  final _reportConcernsController = TextEditingController();
  final _reportHomePlanController = TextEditingController();
  bool _isReportSubmitting = false;
  bool _reportSharedSuccess = false;

  @override
  void initState() {
    super.initState();
    _activeNavIndex = widget.initialTabIndex;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadClinicalData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reportObservationsController.dispose();
    _reportStrengthsController.dispose();
    _reportConcernsController.dispose();
    _reportHomePlanController.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadClinicalData() async {
    setState(() => _isLoading = true);
    final children = await ClinicalService.instance.fetchChildren();
    DailySessionModel? session;
    if (children.isNotEmpty) {
      _selectedChild ??= children.first;
      _pendingGoalIds.clear();
      for (final g in _selectedChild!.activeGoals) {
        _pendingGoalIds.add(g.goalId);
      }
      session = await ClinicalService.instance.fetchDailySession(
        childId: _selectedChild!.id,
        dateString: _selectedDate,
      );
      _populateReportFields(session.therapistReport);
    }

    if (mounted) {
      setState(() {
        _children = children;
        _currentSession = session;
        _isLoading = false;
      });
    }
  }

  void _populateReportFields(TherapistReportModel? report) {
    if (report != null) {
      _reportObservationsController.text = report.summary;
      _reportStrengthsController.text = report.strengths;
      _reportConcernsController.text = report.areasOfConcern;
      _reportHomePlanController.text = report.homeRecommendations;
      _reportSharedSuccess = report.sharedWithParent;
    } else {
      _reportObservationsController.text = 'Patient demonstrated stable sustained engagement across visual and cognitive routines today.';
      _reportStrengthsController.text = 'High compliance in hygiene ADL sequences and sensory breathing pacing.';
      _reportConcernsController.text = 'Occasional erratic taps during high-speed color seriation transitions.';
      _reportHomePlanController.text = 'Parent to practice two-handed cup drinking and 4-step hand washing with verbal praise.';
      _reportSharedSuccess = false;
    }
  }

  Future<void> _onSelectChild(ChildProfile child) async {
    setState(() {
      _selectedChild = child;
      _pendingGoalIds.clear();
      for (final g in child.activeGoals) {
        _pendingGoalIds.add(g.goalId);
      }
      _isLoading = true;
    });

    final session = await ClinicalService.instance.fetchDailySession(
      childId: child.id,
      dateString: _selectedDate,
    );
    _populateReportFields(session.therapistReport);

    if (mounted) {
      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
    }
  }

  Future<void> _onDateChanged(DateTime newDate) async {
    final dateStr = _formatDate(newDate);
    setState(() {
      _selectedDate = dateStr;
      _isLoading = true;
    });

    if (_selectedChild != null) {
      final session = await ClinicalService.instance.fetchDailySession(
        childId: _selectedChild!.id,
        dateString: dateStr,
      );
      _populateReportFields(session.therapistReport);

      if (mounted) {
        setState(() {
          _currentSession = session;
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // GATEKEEPING ACCESS CONTROL CHECK
  // ==========================================
  bool get _isAuthorized {
    final role = AuthService.instance.userRole;
    return role == 'therapist' || role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    // If authenticated user is parent or unauthorized, block them immediately
    if (!_isAuthorized) {
      return _buildAccessDeniedScreen(context);
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100 Clinical Backdrop
      body: Row(
        children: [
          // Sidebar Navigation Rail
          _buildSidebar(isWide),

          // Main Content View
          Expanded(
            child: Column(
              children: [
                // Top Global Clinical Bar
                _buildTopBar(),

                // Workspace Body
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                        )
                      : IndexedStack(
                          index: _activeNavIndex,
                          children: [
                            _buildChildrenDirectoryView(),
                            _buildGoalAssignmentStudioView(),
                            _buildTelemetryInspectorView(),
                            _buildReportGeneratorView(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACCESS DENIED SCREEN (Strict Rule Enforcement)
  // ==========================================
  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_bad_rounded, size: 42, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Access Denied: Clinical Portal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Strict Access Control Policy:\n\n'
                'Parents do NOT have permission to register children, delete records, or classify autism severity levels. '
                'Only certified Therapists and Clinical Administrators can access clinical goal studios and telemetry records.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    key: const Key('return_to_login_btn'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const TherapistLoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Therapist Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SIDEBAR NAVIGATION
  // ==========================================
  Widget _buildSidebar(bool isWide) {
    final width = isWide ? 280.0 : 80.0;
    final role = AuthService.instance.userRole;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          // Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parwarish.ai',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          role == 'admin' ? 'Clinical Admin' : 'Therapist Suite',
                          style: const TextStyle(
                            color: Color(0xFF14B8A6),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // User Profile Card
          if (isWide)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF0D9488),
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AuthService.instance.currentUserName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AuthService.instance.licenseNumber,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Navigation Links
          _buildNavItem(0, 'Children Directory', Icons.people_alt_rounded, isWide, 'nav_children_btn'),
          _buildNavItem(1, 'Goal Studio', Icons.track_changes_rounded, isWide, 'nav_goals_btn'),
          _buildNavItem(2, 'Telemetry Inspector', Icons.analytics_rounded, isWide, 'nav_telemetry_btn'),
          _buildNavItem(3, 'Daily Report', Icons.assignment_turned_in_rounded, isWide, 'nav_report_btn'),

          const Spacer(),

          // Logout Action
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              key: const Key('therapist_logout_btn'),
              onTap: () async {
                await AuthService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TherapistLoginScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                    if (isWide) ...[
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Exit Workspace',
                          style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, bool isWide, String keyName) {
    final isSelected = _activeNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        key: Key(keyName),
        onTap: () => setState(() => _activeNavIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
              if (isWide) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR (Search, Active Child, Date)
  // ==========================================
  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Active Child Selector Pill
          if (_selectedChild != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.child_care_rounded, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Text(
                    'Active: ${_selectedChild!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 6),
                  _buildAutismBadge(_selectedChild!.autismLevel, isCompact: true),
                ],
              ),
            ),

          const Spacer(),

          // Date Picker Quick Indicator
          InkWell(
            key: const Key('session_date_picker_btn'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(_selectedDate),
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                await _onDateChanged(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    'Date: $_selectedDate',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AuthService.instance.isAdmin ? const Color(0xFF0284C7) : const Color(0xFF0D9488),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AuthService.instance.isAdmin ? 'ADMIN' : 'THERAPIST',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: CHILDREN DIRECTORY & MANAGEMENT
  // ==========================================
  Widget _buildChildrenDirectoryView() {
    final filtered = _children.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.autismLevel.toLowerCase().contains(_searchQuery) ||
          c.parentUid.toLowerCase().contains(_searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Child Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Children Clinical Directory',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage clinical assignments, severity classifications, and baseline profiles',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                key: const Key('add_child_modal_btn'),
                onPressed: _showAddChildModal,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Child Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              key: const Key('child_search_field'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search child by name, parent UID, or autism level...',
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Children Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No children found matching query.', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (context, index) {
                      final child = filtered[index];
                      final isSelected = _selectedChild?.id == child.id;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          key: Key('child_row_${child.id}'),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFF0FDFA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFCCFBF1),
                            child: Text(
                              child.name.isNotEmpty ? child.name[0] : 'C',
                              style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                child.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 10),
                              _buildAutismBadge(child.autismLevel),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${child.currentStreak}d Streak',
                                  style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Parent ID: ${child.parentUid} • Struggle Flags: ${child.struggleFlags} • Active Goals: ${child.activeGoals.length}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                key: Key('select_child_${child.id}'),
                                onPressed: () => _onSelectChild(child),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9),
                                  foregroundColor: isSelected ? Colors.white : const Color(0xFF334155),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(isSelected ? 'Active' : 'Select'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                key: Key('delete_child_${child.id}'),
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                tooltip: 'Delete / Archive Child Record',
                                onPressed: () => _showDeleteConfirmDialog(child),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: DOMAIN & GOAL ASSIGNMENT STUDIO
  // ==========================================
  Widget _buildGoalAssignmentStudioView() {
    if (_selectedChild == null) {
      return const Center(child: Text('Select a child to assign clinical goals.'));
    }

    final activeDomain = ClinicalTaxonomy.getDomainById(_selectedDomainId) ?? ClinicalTaxonomy.domains.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.track_changes_rounded, color: Color(0xFF14B8A6), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Goal Studio: ${_selectedChild!.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Map goals across 22 behavioral domains. Assigned goals dynamically drive child mobile lessons.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('push_goals_btn'),
                  onPressed: _pushGoalsToChild,
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Push Goals to Child App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Two Column Studio: Domain Selector on Left, Sub-Goals Checklist on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Domain Selector (All 22 Domains)
              Expanded(
                flex: 4,
                child: Container(
                  height: 600,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '22 Clinical Domains',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: ClinicalTaxonomy.domains.length,
                          itemBuilder: (context, index) {
                            final d = ClinicalTaxonomy.domains[index];
                            final isDomainSelected = d.id == _selectedDomainId;

                            // Count assigned goals in this domain
                            final countInDomain = _pendingGoalIds.where((gid) => gid.startsWith('g_${d.id.toString().padLeft(2, '0')}')).length;

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                key: Key('domain_item_${d.id}'),
                                selected: isDomainSelected,
                                selectedTileColor: const Color(0xFFF0FDFA),
                                leading: Icon(d.icon, color: isDomainSelected ? const Color(0xFF0D9488) : d.themeColor, size: 20),
                                title: Text(
                                  '${d.id}. ${d.name}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isDomainSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isDomainSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                                  ),
                                ),
                                trailing: countInDomain > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$countInDomain',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : null,
                                onTap: () => setState(() => _selectedDomainId = d.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Sub-Goals Picker on Right
              Expanded(
                flex: 6,
                child: Container(
                  height: 600,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(activeDomain.icon, color: activeDomain.themeColor, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeDomain.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  activeDomain.description,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),

                      const Text(
                        'Target Goal Checklist (Select to Assign)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: activeDomain.subGoals.length,
                          itemBuilder: (context, idx) {
                            final g = activeDomain.subGoals[idx];
                            final isChecked = _pendingGoalIds.contains(g.goalId);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: isChecked ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isChecked ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                                    width: isChecked ? 1.5 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                key: Key('goal_checkbox_${g.goalId}'),
                                value: isChecked,
                                activeColor: const Color(0xFF0D9488),
                                title: Text(
                                  g.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(g.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildBadge('Module: ${g.moduleName}', const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
                                        _buildBadge(g.interactionType.toUpperCase(), const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                                      ],
                                    ),
                                  ],
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _pendingGoalIds.add(g.goalId);
                                    } else {
                                      _pendingGoalIds.remove(g.goalId);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pushGoalsToChild() async {
    if (_selectedChild == null) return;

    // Build ActiveGoalItem list
    final List<ActiveGoalItem> newActiveGoals = [];
    for (final domain in ClinicalTaxonomy.domains) {
      for (final subGoal in domain.subGoals) {
        if (_pendingGoalIds.contains(subGoal.goalId)) {
          newActiveGoals.add(
            ActiveGoalItem(
              goalId: subGoal.goalId,
              domainId: domain.id,
              domainName: domain.name,
              goalTitle: subGoal.title,
              assignedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    await ClinicalService.instance.pushGoalsToChild(
      childId: _selectedChild!.id,
      goals: newActiveGoals,
      callerRole: AuthService.instance.userRole,
    );

    setState(() {
      _selectedChild = _selectedChild!.copyWith(activeGoals: newActiveGoals);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully pushed ${newActiveGoals.length} goals to ${_selectedChild!.name}! Mobile app updated.'),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
    }
  }

  // ==========================================
  // VIEW 3: DAILY TELEMETRY & SESSION INSPECTOR
  // ==========================================
  Widget _buildTelemetryInspectorView() {
    final session = _currentSession;
    final totalMins = session != null ? (session.totalActiveSeconds / 60).round() : 0;
    final completionPct = session != null ? (session.completionRate * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Telemetry Inspector: ${_selectedChild?.name ?? 'Child'}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Session analytics, errant tap counters, and mood sensors for $_selectedDate',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Aggregated KPI Cards (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 720;
              final cardWidth = isDesktop
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: _buildKpiCard('Total Active Time', '${totalMins}m', Icons.timer_rounded, const Color(0xFF3B82F6), 'kpi_time')),
                  SizedBox(width: cardWidth, child: _buildKpiCard('Completion Rate', '$completionPct%', Icons.check_circle_rounded, const Color(0xFF10B981), 'kpi_completion')),
                  SizedBox(width: cardWidth, child: _buildKpiCard('Detected Mood', session?.overallMoodDetected ?? 'Calm', Icons.sentiment_very_satisfied_rounded, const Color(0xFFF59E0B), 'kpi_mood')),
                  SizedBox(width: cardWidth, child: _buildKpiCard('Struggle / Errant Taps', '${session?.struggleIncidents ?? 0}', Icons.warning_amber_rounded, const Color(0xFFEF4444), 'kpi_struggle')),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Granular Session Logs Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Granular Module Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chronological stream of each mini-game or interactive lesson attempted during this session',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                if (session == null || session.sessionLogs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No module logs recorded for this day yet.')),
                  )
                else
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(2),
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: [
                          _buildTableHeaderCell('Module & Goal'),
                          _buildTableHeaderCell('Mode'),
                          _buildTableHeaderCell('Duration'),
                          _buildTableHeaderCell('Status'),
                          _buildTableHeaderCell('Struggle Taps'),
                        ],
                      ),
                      // Data Rows
                      for (final log in session.sessionLogs)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text(log.moduleName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text(log.interactionType, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text('${log.durationSeconds}s', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  Icon(log.completed ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: log.completed ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(log.completed ? 'Passed' : 'Abandoned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: log.completed ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text('${log.errantTaps}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: log.errantTaps > 2 ? const Color(0xFFEF4444) : const Color(0xFF475569))),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, String keyName) {
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
    );
  }

  // ==========================================
  // VIEW 4: DAILY REPORT GENERATOR & PARENT MESSENGER
  // ==========================================
  Widget _buildReportGeneratorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Daily Report: ${_selectedChild?.name ?? 'Child'}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publish certified telemetry summary and home reinforcement instructions for $_selectedDate',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_reportSharedSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 6),
                      Text('Published to Parent App', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Form Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Therapist Clinical Observations & Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('report_summary_field'),
                  controller: _reportObservationsController,
                  maxLines: 3,
                  decoration: _buildFormFieldDecoration('Describe session engagement, emotional stability, and overall tone...'),
                ),
                const SizedBox(height: 18),

                const Text('Behavioral Strengths & Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('report_strengths_field'),
                  controller: _reportStrengthsController,
                  maxLines: 2,
                  decoration: _buildFormFieldDecoration('Specific milestones achieved today (e.g. Completed tooth brushing routine)...'),
                ),
                const SizedBox(height: 18),

                const Text('Areas of Concern / Sensory Triggers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('report_concerns_field'),
                  controller: _reportConcernsController,
                  maxLines: 2,
                  decoration: _buildFormFieldDecoration('Noted frustration, errant taps, or sensory overwhelming triggers...'),
                ),
                const SizedBox(height: 18),

                const Text('Home Reinforcement & Practice Plan for Parents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('report_home_plan_field'),
                  controller: _reportHomePlanController,
                  maxLines: 3,
                  decoration: _buildFormFieldDecoration('Concrete activities parents should practice at home tonight (e.g. 4-step hand washing)...'),
                ),
                const SizedBox(height: 24),

                // Finalize and Send Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('finalize_and_send_btn'),
                      onPressed: _isReportSubmitting ? null : _finalizeAndSendReport,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isReportSubmitting ? 'Publishing...' : 'Finalize & Send to Parent Mobile App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeAndSendReport() async {
    if (_selectedChild == null) return;
    setState(() => _isReportSubmitting = true);

    final report = TherapistReportModel(
      summary: _reportObservationsController.text.trim(),
      strengths: _reportStrengthsController.text.trim(),
      areasOfConcern: _reportConcernsController.text.trim(),
      homeRecommendations: _reportHomePlanController.text.trim(),
      submittedAt: DateTime.now(),
      therapistName: AuthService.instance.currentUserName,
      sharedWithParent: true,
    );

    await ClinicalService.instance.publishTherapistReport(
      childId: _selectedChild!.id,
      dateString: _selectedDate,
      report: report,
      callerRole: AuthService.instance.userRole,
    );

    setState(() {
      _isReportSubmitting = false;
      _reportSharedSuccess = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report finalized and published to Parent Dashboard for ${_selectedChild!.name}!'),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
    }
  }

  InputDecoration _buildFormFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
    );
  }

  // ==========================================
  // MODALS: ADD CHILD & DELETE CHILD
  // ==========================================
  void _showAddChildModal() {
    final nameCtrl = TextEditingController();
    final parentUidCtrl = TextEditingController(text: 'parent_demo_01');
    DateTime selectedDob = DateTime(2019, 5, 20);
    String selectedLevel = 'Mild';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Child Profile (Therapist/Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Child Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('modal_child_name_input'),
                      controller: nameCtrl,
                      decoration: _buildFormFieldDecoration('e.g. Ibrahim'),
                    ),
                    const SizedBox(height: 14),

                    const Text('Linked Parent UID / Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('modal_parent_uid_input'),
                      controller: parentUidCtrl,
                      decoration: _buildFormFieldDecoration('parent_demo_01'),
                    ),
                    const SizedBox(height: 14),

                    const Text('Autism Severity Classification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: const Key('modal_autism_level_select'),
                      value: selectedLevel,
                      items: const [
                        DropdownMenuItem(value: 'Mild', child: Text('Level 1 - Mild (Requiring Support)')),
                        DropdownMenuItem(value: 'Moderate', child: Text('Level 2 - Moderate (Substantial Support)')),
                        DropdownMenuItem(value: 'Severe', child: Text('Level 3 - Severe (Very Substantial Support)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedLevel = val);
                      },
                      decoration: _buildFormFieldDecoration(''),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DOB: ${_formatDate(selectedDob)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDob,
                              firstDate: DateTime(2012),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDob = picked);
                            }
                          },
                          child: const Text('Select Date', style: TextStyle(color: Color(0xFF0D9488))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  key: const Key('modal_save_child_btn'),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(dialogCtx);

                    final created = await ClinicalService.instance.createChild(
                      name: nameCtrl.text.trim(),
                      dateOfBirth: selectedDob,
                      parentUid: parentUidCtrl.text.trim(),
                      autismLevel: selectedLevel,
                      createdByUid: AuthService.instance.currentUserUid,
                      callerRole: AuthService.instance.userRole,
                    );

                    await _loadClinicalData();
                    _onSelectChild(created);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Child Profile'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(ChildProfile child) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Archive / Delete Record?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently remove ${child.name}? '
            'This action deletes active clinical goals and historical telemetry sessions from the system.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              key: const Key('confirm_delete_child_btn'),
              onPressed: () async {
                Navigator.pop(ctx);
                await ClinicalService.instance.deleteChild(
                  childId: child.id,
                  callerRole: AuthService.instance.userRole,
                );
                await _loadClinicalData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm Deletion'),
            ),
          ],
        );
      },
    );
  }

  // Helpers
  Widget _buildAutismBadge(String level, {bool isCompact = false}) {
    Color bg;
    Color fg;
    switch (level.toLowerCase()) {
      case 'severe':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case 'moderate':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: isCompact ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        isCompact ? level : 'Level: $level',
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: isCompact ? 10 : 11),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
