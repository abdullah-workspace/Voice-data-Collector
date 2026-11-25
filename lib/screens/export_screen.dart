import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/services/export_service.dart';

/// Screen for exporting the complete dataset and metadata as a structured ZIP file.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  double _progress = 0.0;
  String? _exportedZipPath;
  String? _errorMessage;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _startExport() async {
    final dataset = context.read<DatasetProvider>();

    if (dataset.totalCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot export: No audio recordings in dataset yet.'),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _errorMessage = null;
      _exportedZipPath = null;
    });

    try {
      final exportService =
          ExportService(storageService: dataset.storageService);

      final zipPath = await exportService.exportDataset((progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      });

      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _exportedZipPath = zipPath;
      });

      await _shareZipFile(zipPath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.errorCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareZipFile(String zipPath) async {
    try {
      final file = File(zipPath);
      if (await file.exists()) {
        final xFile = XFile(zipPath, mimeType: 'application/zip');
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            subject: 'HearAssist Audio Dataset',
            text: 'HearAssist environmental sound dataset archive.',
          ),
        );
      } else {
        throw StateError('Exported ZIP file not found at $zipPath');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open share sheet: $e'),
            backgroundColor: AppColors.errorCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataset = context.watch<DatasetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Dataset'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCobalt.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.secondaryCobalt,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HearAssist Dataset Package',
                              style: isDark
                                  ? AppTypography.cardTitleDark
                                  : AppTypography.cardTitle,
                            ),
                            Text(
                              'ZIP archive containing all folders & CSV',
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
                  const SizedBox(height: 14),
                  _buildStatRow(
                    isDark: isDark,
                    label: 'Total Audio Samples',
                    value: '${dataset.totalCount} WAV files',
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    isDark: isDark,
                    label: 'Uncompressed Size',
                    value: _formatBytes(dataset.totalStorageBytes),
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    isDark: isDark,
                    label: 'Sound Categories',
                    value: '6 Class Folders',
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    isDark: isDark,
                    label: 'Metadata Registry',
                    value: 'metadata.csv',
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    isDark: isDark,
                    label: 'Format',
                    value: 'ZIP (Preserves Folder Tree)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Directory Tree Preview
            Text(
              'Archive Folder Structure',
              style: isDark
                  ? AppTypography.sectionHeadingDark
                  : AppTypography.sectionHeading,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderIce,
                ),
              ),
              child: const Text(
                'HearAssistDataset/\n'
                '  ├── clapping/\n'
                '  ├── doorbell/\n'
                '  ├── door_knock/\n'
                '  ├── baby_cry/\n'
                '  ├── microwave_oven/\n'
                '  ├── background_noise/\n'
                '  └── metadata.csv',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Export Progress Bar
            if (_isExporting) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compressing Dataset Archive...',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryCobalt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 7,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondaryCobalt,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorCoral),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.errorCoral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Export Error: $_errorMessage',
                        style: const TextStyle(color: AppColors.errorCoral, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_exportedZipPath != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successEmerald),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.successEmerald),
                        SizedBox(width: 8),
                        Text(
                          'ZIP Archive Created Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.successEmerald,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Archive saved to: $_exportedZipPath',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _startExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.archive_rounded, size: 20),
                label: Text(
                  _isExporting
                      ? 'Packaging Dataset...'
                      : _exportedZipPath != null
                          ? 'Re-export & Share'
                          : 'Create ZIP & Share',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryCobalt,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_exportedZipPath != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareZipFile(_exportedZipPath!),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Open Share Sheet Again'),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
