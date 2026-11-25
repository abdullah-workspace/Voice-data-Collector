import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/providers/settings_provider.dart';
import 'package:hearassist_data_collector/screens/library_screen.dart';
import 'package:hearassist_data_collector/screens/record_screen.dart';
import 'package:hearassist_data_collector/screens/settings_screen.dart';
import 'package:hearassist_data_collector/widgets/category_card.dart';

/// Main dashboard displaying progress across all 6 sound categories.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatasetProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTabIndex,
        children: const [
          _HomeDashboardView(),
          LibraryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedTabIndex = index);
          if (index == 0 || index == 1) {
            context.read<DatasetProvider>().refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataset = context.watch<DatasetProvider>();
    final settings = context.watch<SettingsProvider>();

    final totalTarget =
        SoundCategory.allCategories.length * settings.targetPerCategory;
    final totalProgress = totalTarget > 0
        ? (dataset.totalCount / totalTarget).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (totalProgress * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8)),
            const SizedBox(width: 10),
            const Text('HearAssist Data Collector'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh dataset counts',
            onPressed: () => context.read<DatasetProvider>().refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.secondaryCobalt,
        onRefresh: () => context.read<DatasetProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Progress Overview Banner
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryObsidian,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryObsidian.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DATASET COLLECTION',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCobalt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percentage%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${dataset.totalCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ $totalTarget total samples',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryCobalt,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  settings.collectorName.isEmpty
                                      ? 'No collector set'
                                      : settings.collectorName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_android_outlined,
                                size: 14,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  settings.deviceLabel.isEmpty
                                      ? 'No device set'
                                      : settings.deviceLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Categories Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sound Categories',
                    style: isDark
                        ? AppTypography.sectionHeadingDark
                        : AppTypography.sectionHeading,
                  ),
                  Text(
                    '6 Classes',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Select a category to record 2s or 3s audio clips',
                style: isDark
                    ? AppTypography.secondaryDescriptionDark
                    : AppTypography.secondaryDescription,
              ),

              const SizedBox(height: 14),

              // Categories 2-Column Grid (Aspect ratio 0.81 ensures zero overflow on all phone screens)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.81,
                ),
                itemCount: SoundCategory.allCategories.length,
                itemBuilder: (context, index) {
                  final category = SoundCategory.allCategories[index];
                  final count =
                      dataset.categoryCounts[category.folderName] ?? 0;

                  return CategoryCard(
                    category: category,
                    count: count,
                    target: settings.targetPerCategory,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecordScreen(category: category.id),
                        ),
                      );
                      if (context.mounted) {
                        context.read<DatasetProvider>().refresh();
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
