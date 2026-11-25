import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/models/recording_model.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/widgets/recording_list_item.dart';

/// Screen for browsing, playing, and deleting collected dataset audio recordings.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selectedCategory; // null means 'All'
  List<RecordingModel> _recordings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    try {
      final dataset = context.read<DatasetProvider>();
      final items = await dataset.loadRecordings(category: _selectedCategory);
      if (mounted) {
        setState(() => _recordings = items);
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(RecordingModel recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: Text(
          'Are you sure you want to permanently delete:\n\n${recording.filename}\n\n'
          'This will remove both the audio file and its metadata record from metadata.csv.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorCoral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<DatasetProvider>().deleteRecording(recording);
      await _loadRecordings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted: ${recording.filename}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload files',
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderIce,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SAMPLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dataset.totalCount} recordings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'STORAGE USED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTotalStorage(dataset.totalStorageBytes),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryCobalt,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Categories'),
                  selected: _selectedCategory == null,
                  selectedColor: AppColors.secondaryCobalt.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _selectedCategory == null
                        ? AppColors.secondaryCobalt
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  side: BorderSide(
                    color: _selectedCategory == null
                        ? AppColors.secondaryCobalt
                        : (isDark ? AppColors.darkBorder : AppColors.borderIce),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = null);
                      _loadRecordings();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...SoundCategory.allCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.folderName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: AppColors.secondaryCobalt.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.secondaryCobalt
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.secondaryCobalt
                            : (isDark ? AppColors.darkBorder : AppColors.borderIce),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat.folderName : null;
                        });
                        _loadRecordings();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Recording List Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.secondaryCobalt),
                  )
                : _recordings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryCobalt.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 36,
                                  color: AppColors.secondaryCobalt,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'No recordings found',
                                style: isDark
                                    ? AppTypography.cardTitleDark
                                    : AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedCategory != null
                                    ? 'No recordings collected for this category yet.'
                                    : 'Start collecting samples from the dashboard.',
                                style: isDark
                                    ? AppTypography.secondaryDescriptionDark
                                    : AppTypography.secondaryDescription,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.secondaryCobalt,
                        onRefresh: _loadRecordings,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          itemCount: _recordings.length,
                          itemBuilder: (context, index) {
                            final recording = _recordings[index];
                            return RecordingListItem(
                              key: ValueKey(recording.filepath),
                              recording: recording,
                              onDelete: () => _confirmDelete(recording),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
