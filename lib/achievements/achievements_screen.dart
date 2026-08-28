import 'package:flutter/material.dart';
import 'package:trego/achievements/achievement_model.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

class AchievementsScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [AchievementService].
  final AchievementService? service;

  const AchievementsScreen({super.key, this.service});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  // Lazily constructed: these touch Firebase on first access, which must
  // not happen synchronously during State construction (it would crash
  // build() before a frame is ever produced, including in test hosts where
  // Firebase isn't initialized).
  late final AchievementService _achievementService = widget.service ?? AchievementService();
  late final AuthService _authService = AuthService();

  String? _userId;
  bool _isLoading = true;
  List<Achievement> _achievements = [];
  String _selectedCategory = 'all';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    try {
      _userId = _authService.currentUser?.uid;
    } catch (_) {
      // Auth unavailable (e.g. Firebase not configured in this context);
      // treat as signed-out.
      _userId = null;
    }

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadAchievements();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final achievements = await _achievementService.getUserAchievements(_userId!);

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });

        // Start animations
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      print('Error loading achievements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'all') {
      return _achievements;
    }
    return _achievements.where((achievement) => achievement.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: tokens.brand,
              ),
            )
          : CustomScrollView(
              slivers: [
                // Hero Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(Space.lg),
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.brandContainerStart,
                          tokens.brandContainerEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.brand.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(Space.md),
                                  decoration: BoxDecoration(
                                    color: tokens.onBrand.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(Radii.statTile),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: tokens.onBrand,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: Space.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Achievements',
                                        style: context.typo.title.copyWith(
                                          color: tokens.onBrand,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Track your fitness milestones',
                                        style: context.typo.body.copyWith(
                                          color: tokens.onBrand.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.xl),

                            // Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '🏆',
                                    value: '${_achievementService.getEarnedCount(_achievements)}',
                                    label: 'Earned',
                                    color: tokens.onBrand,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '🎯',
                                    value: '${_achievementService.getTotalCount(_achievements)}',
                                    label: 'Total',
                                    color: tokens.onBrand,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Category Filter
                SliverToBoxAdapter(
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: achievementCategories.length + 1, // +1 for "All"
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildCategoryChip('all', 'All', '🏆', isSelected: _selectedCategory == 'all');
                        }
                        final category = achievementCategories[index - 1];
                        return _buildCategoryChip(
                          category.id,
                          category.name,
                          category.icon,
                          isSelected: _selectedCategory == category.id,
                        );
                      },
                    ),
                  ),
                ),

                // Achievements Grid
                SliverPadding(
                  padding: const EdgeInsets.all(Space.lg),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: Space.lg,
                      mainAxisSpacing: Space.lg,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievement = _filteredAchievements[index];
                        return _buildAchievementCard(achievement);
                      },
                      childCount: _filteredAchievements.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroStat({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: Space.sm),
        Text(
          value,
          style: context.typo.stat.copyWith(
            color: color,
          ),
        ),
        Text(
          label,
          style: context.typo.bodySmall.copyWith(
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String id, String name, String icon, {required bool isSelected}) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: Space.md),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
        decoration: BoxDecoration(
          color: isSelected ? tokens.brand : tokens.surface,
          borderRadius: BorderRadius.circular(Radii.screenWrapper),
          border: Border.all(
            color: isSelected ? tokens.brand : tokens.border,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: tokens.brand.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: Space.sm),
            Text(
              name,
              style: context.typo.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? tokens.onBrand : tokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement),
      child: Card(
        elevation: achievement.isEarned ? 8 : 2,
        shadowColor: achievement.isEarned
            ? tokens.brand.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.screenWrapper),
            gradient: achievement.isEarned
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tokens.brandContainerStart,
                      tokens.brandContainerEnd,
                    ],
                  )
                : null,
            color: achievement.isEarned ? null : tokens.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: achievement.isEarned
                        ? tokens.onBrand.withValues(alpha: 0.2)
                        : tokens.surfaceSunken,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: Space.md),

                // Title
                Text(
                  achievement.title,
                  style: context.typo.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: achievement.isEarned ? tokens.onBrand : tokens.ink,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.sm),

                // Progress or Earned Date
                if (achievement.isEarned && achievement.earnedAt != null)
                  Text(
                    'Earned ${_formatDate(achievement.earnedAt!)}',
                    style: context.typo.bodySmall.copyWith(
                      color: tokens.onBrand.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  )
                else if (!achievement.isEarned && achievement.progress != null)
                  Text(
                    achievement.progress!,
                    style: context.typo.bodySmall.copyWith(
                      color: tokens.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                // Progress Bar (for unearned achievements)
                if (!achievement.isEarned && achievement.currentValue != null)
                  Container(
                    margin: const EdgeInsets.only(top: Space.sm),
                    child: LinearProgressIndicator(
                      value: (achievement.currentValue! / achievement.requirement).clamp(0.0, 1.0),
                      backgroundColor: tokens.border,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.brand),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: Space.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  children: [
                    // Achievement Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: achievement.isEarned
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  tokens.brandContainerStart,
                                  tokens.brandContainerEnd,
                                ],
                              )
                            : null,
                        color: achievement.isEarned ? null : tokens.surfaceSunken,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.xl),

                    // Title
                    Text(
                      achievement.title,
                      style: context.typo.title.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.md),

                    // Description
                    Text(
                      achievement.description,
                      style: context.typo.body.copyWith(
                        color: tokens.inkMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.xl),

                    // Progress or Earned Date
                    if (achievement.isEarned && achievement.earnedAt != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                        decoration: BoxDecoration(
                          color: tokens.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Radii.screenWrapper),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: tokens.success,
                              size: 20,
                            ),
                            const SizedBox(width: Space.sm),
                            Text(
                              'Earned ${_formatDate(achievement.earnedAt!)}',
                              style: context.typo.body.copyWith(
                                color: tokens.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                        decoration: BoxDecoration(
                          color: tokens.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Radii.screenWrapper),
                        ),
                        child: Text(
                          '${achievement.currentValue ?? 0} / ${achievement.requirement} ${achievement.unit}',
                          style: context.typo.body.copyWith(
                            color: tokens.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      if (achievement.progress != null)
                        LinearProgressIndicator(
                          value: (achievement.currentValue ?? 0) / achievement.requirement,
                          backgroundColor: tokens.border,
                          valueColor: AlwaysStoppedAnimation<Color>(tokens.brand),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                    ],

                    const Spacer(),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.ink,
                          foregroundColor: tokens.canvas,
                          padding: const EdgeInsets.symmetric(vertical: Space.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.standardCard),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
