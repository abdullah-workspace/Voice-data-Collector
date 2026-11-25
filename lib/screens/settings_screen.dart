import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/providers/settings_provider.dart';
import 'package:hearassist_data_collector/screens/export_screen.dart';

/// Screen for configuring collector details, recording duration (2s/3s), and targets.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _collectorController;
  late final TextEditingController _deviceController;
  late final TextEditingController _targetController;

  late int _selectedDuration; // strictly 2 or 3
  bool _isSaving = false;
  bool _isAboutExpanded = false; // Collapsed by default

  // Initial saved snapshots for dirty checking
  late String _savedCollector;
  late String _savedDevice;
  late int _savedDuration;
  late String _savedTarget;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();

    _savedCollector = settings.collectorName;
    _savedDevice = settings.deviceLabel;
    _savedDuration = (settings.recordingDuration == 2) ? 2 : 3;
    _savedTarget = settings.targetPerCategory.toString();

    _collectorController = TextEditingController(text: _savedCollector);
    _deviceController = TextEditingController(text: _savedDevice);
    _targetController = TextEditingController(text: _savedTarget);
    _selectedDuration = _savedDuration;

    _collectorController.addListener(_onFieldChanged);
    _deviceController.addListener(_onFieldChanged);
    _targetController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    return _collectorController.text.trim() != _savedCollector ||
        _deviceController.text.trim() != _savedDevice ||
        _selectedDuration != _savedDuration ||
        _targetController.text.trim() != _savedTarget;
  }

  @override
  void dispose() {
    _collectorController.removeListener(_onFieldChanged);
    _deviceController.removeListener(_onFieldChanged);
    _targetController.removeListener(_onFieldChanged);

    _collectorController.dispose();
    _deviceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final collector = _collectorController.text.trim();
    final device = _deviceController.text.trim();

    if (collector.isEmpty || device.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collector name and Device label cannot be empty.'),
          backgroundColor: AppColors.errorCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetVal = int.tryParse(_targetController.text.trim()) ?? 200;
    if (targetVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Target recordings per category must be greater than 0.',
          ),
          backgroundColor: AppColors.errorCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settings = context.read<SettingsProvider>();
      await settings.saveSettings(
        collectorName: collector,
        deviceLabel: device,
        recordingDuration: _selectedDuration,
        targetPerCategory: targetVal,
      );

      // Update baseline snapshots
      _savedCollector = collector;
      _savedDevice = device;
      _savedDuration = _selectedDuration;
      _savedTarget = targetVal.toString();

      if (mounted) {
        // Refresh dashboard counts
        context.read<DatasetProvider>().refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: AppColors.successEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.errorCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _discardChanges() {
    _collectorController.text = _savedCollector;
    _deviceController.text = _savedDevice;
    _selectedDuration = _savedDuration;
    _targetController.text = _savedTarget;
    setState(() {});
  }

  Future<bool> _promptUnsavedChanges() async {
    if (!_hasChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes in Settings. Do you want to discard them?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep Editing'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorCoral,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (discard == true) {
      _discardChanges();
      return true;
    }

    return false;
  }

  String _formatTotalStorage(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataset = context.watch<DatasetProvider>();

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _promptUnsavedChanges().then((canLeave) {
            if (canLeave && context.mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        bottomNavigationBar: _hasChanges
            ? _buildUnsavedChangesPopUp(isDark)
            : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Collector Information Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.badge_outlined,
                  title: 'Collector Information',
                  subtitle:
                      'Attributed in filenames (<category>_<collector>_<device>_<NNNN>.wav)',
                  children: [
                    // Collector Name
                    TextFormField(
                      controller: _collectorController,
                      decoration: const InputDecoration(
                        labelText: 'Collector Name',
                        hintText: 'e.g. abdullah',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Collector name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Device Label
                    TextFormField(
                      controller: _deviceController,
                      decoration: const InputDecoration(
                        labelText: 'Device Label / Model',
                        hintText: 'e.g. samsungA14',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Device label is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section 2: Recording Preferences Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.tune_rounded,
                  title: 'Recording Preferences',
                  subtitle:
                      'Acoustic specifications: PCM 16-bit, 16 kHz Mono WAV',
                  children: [
                    Text(
                      'Recording Duration',
                      style: isDark
                          ? AppTypography.labelDark
                          : AppTypography.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fixed duration options for environmental sound samples',
                      style: isDark
                          ? AppTypography.captionDark
                          : AppTypography.caption,
                    ),
                    const SizedBox(height: 10),

                    // Segmented selection strictly 2s or 3s (5s removed)
                    SegmentedButton<int>(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      segments: const [
                        ButtonSegment<int>(
                          value: 2,
                          label: Text('2 Seconds'),
                          icon: Icon(Icons.timer_outlined, size: 18),
                        ),
                        ButtonSegment<int>(
                          value: 3,
                          label: Text('3 Seconds (Default)'),
                          icon: Icon(Icons.timer, size: 18),
                        ),
                      ],
                      selected: {_selectedDuration},
                      onSelectionChanged: (newSelection) {
                        if (newSelection.isNotEmpty) {
                          setState(() {
                            _selectedDuration = newSelection.first;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    // Target Recordings Per Category
                    TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Recordings Per Category',
                        hintText: '200',
                        prefixIcon: Icon(Icons.track_changes_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Target count is required';
                        }
                        final num = int.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section 3: Data Management Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.storage_rounded,
                  title: 'Dataset Management',
                  subtitle:
                      'Export collected audio samples and metadata as a structured ZIP',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Dataset Storage:',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatTotalStorage(dataset.totalStorageBytes),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryCobalt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.archive_outlined, size: 20),
                        label: const Text('Export Dataset (ZIP Archive)'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExportScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section 4: Expandable About HearAssist Card
                _buildExpandableAboutCard(isDark),

                const SizedBox(height: 32),

                // Academic & Research Disclaimer
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Developed solely for academic and research purposes. This project is the original work of FYP_G019 Group .',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        letterSpacing: 0.1,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Expandable/Accordion-style About card, collapsed by default.
  Widget _buildExpandableAboutCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderIce,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isAboutExpanded = !_isAboutExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCobalt.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.secondaryCobalt,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About HearAssist',
                          style: isDark
                              ? AppTypography.cardTitleDark
                              : AppTypography.cardTitle,
                        ),
                        Text(
                          'Purpose, acoustic standards & specifications',
                          style: isDark
                              ? AppTypography.captionDark
                              : AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isAboutExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 0.0, 18.0, 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCobalt
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.graphic_eq_rounded,
                              color: AppColors.secondaryCobalt,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HearAssist Data Collector',
                              style: isDark
                                  ? AppTypography.cardTitleDark
                                  : AppTypography.cardTitle,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryCobalt
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'v1.0.0 • Production Build',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryCobalt,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'HearAssist Data Collector is a purpose-engineered acoustic data collection platform designed to capture, validate, and standardize real-world environmental sounds. The curated dataset provides high-fidelity training data for assistive audio detection algorithms designed to empower deaf and hard-of-hearing users.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.backgroundAlabaster,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderIce,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildAboutSpecRow(
                          label: 'Acoustic Standard',
                          value: 'PCM 16-bit, 16 kHz Mono WAV',
                          isDark: isDark,
                        ),
                        const Divider(height: 16),
                        _buildAboutSpecRow(
                          label: 'Sound Categories',
                          value: '6 Standard Classes (5 Active + Noise)',
                          isDark: isDark,
                        ),
                        const Divider(height: 16),
                        _buildAboutSpecRow(
                          label: 'Metadata Standard',
                          value: '11 Standardized CSV Attributes',
                          isDark: isDark,
                        ),
                        const Divider(height: 16),
                        _buildAboutSpecRow(
                          label: 'Privacy & Storage',
                          value: '100% On-Device Storage & Local Export',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isAboutExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  /// Pop-up bar that emerges at the bottom of the screen when user inputs or modifies fields.
  Widget _buildUnsavedChangesPopUp(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderIce,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCobalt.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: AppColors.secondaryCobalt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unsaved changes detected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Strictly horizontal action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _discardChanges,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderIce,
                      ),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryCobalt,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildAboutSpecRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderIce,
        ),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondaryCobalt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.secondaryCobalt, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: isDark
                          ? AppTypography.cardTitleDark
                          : AppTypography.cardTitle,
                    ),
                    Text(
                      subtitle,
                      style: isDark
                          ? AppTypography.captionDark
                          : AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
