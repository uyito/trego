import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../social_service.dart';

/// Decorative accent colors for challenge categories. These are per-type
/// hues with no matching semantic token role (steps reuses tokens.success
/// since it's already a green in the palette).
class _ChallengeColors {
  static const workouts = Color(0xFF2196F3); // ALLOW-HEX: category accent (blue), no token role fits a decorative per-type hue
  static const distance = Color(0xFFFF9800); // ALLOW-HEX: category accent (orange), no token role fits a decorative per-type hue
  static const calories = Color(0xFFF44336); // ALLOW-HEX: category accent (red), no token role fits a decorative per-type hue
  static const weightLoss = Color(0xFF9C27B0); // ALLOW-HEX: category accent (purple), no token role fits a decorative per-type hue
  _ChallengeColors._();
}

class ChallengesScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [SocialService].
  final SocialService? service;

  const ChallengesScreen({super.key, this.service});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late final SocialService _socialService = widget.service ?? SocialService();
  late TabController _tabController;

  List<Map<String, dynamic>> _activeChallenges = [];
  List<Map<String, dynamic>> _availableChallenges = [];
  List<Map<String, dynamic>> _completedChallenges = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);

    try {
      final allChallenges = await _socialService.getChallenges();

      setState(() {
        _activeChallenges = allChallenges.where((c) => c['status'] == 'active' && c['isParticipating'] == true).toList();
        _availableChallenges = allChallenges.where((c) => c['status'] == 'active' && c['isParticipating'] != true).toList();
        _completedChallenges = allChallenges.where((c) => c['status'] == 'completed').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load challenges')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.surfaceSunken,
        foregroundColor: tokens.ink,
        title: Text('Challenges', style: context.typo.title),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: tokens.ink),
            onPressed: _showCreateChallengeDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: tokens.brand,
          unselectedLabelColor: tokens.inkMuted,
          indicatorColor: tokens.brand,
          tabs: [
            Tab(text: 'Active (${_activeChallenges.length})'),
            Tab(text: 'Available (${_availableChallenges.length})'),
            Tab(text: 'Completed (${_completedChallenges.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveChallengesTab(),
          _buildAvailableChallengesTab(),
          _buildCompletedChallengesTab(),
        ],
      ),
    );
  }

  Widget _buildActiveChallengesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeChallenges.isEmpty) {
      final tokens = context.tokens;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No active challenges', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Join a challenge to get started!',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.xl),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Browse Challenges'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        itemCount: _activeChallenges.length,
        itemBuilder: (context, index) => _buildChallengeCard(_activeChallenges[index], isActive: true),
      ),
    );
  }

  Widget _buildAvailableChallengesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableChallenges.isEmpty) {
      final tokens = context.tokens;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No available challenges', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Create your own challenge!',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.xl),
            ElevatedButton(
              onPressed: _showCreateChallengeDialog,
              child: const Text('Create Challenge'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        itemCount: _availableChallenges.length,
        itemBuilder: (context, index) => _buildChallengeCard(_availableChallenges[index]),
      ),
    );
  }

  Widget _buildCompletedChallengesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedChallenges.isEmpty) {
      final tokens = context.tokens;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No completed challenges', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Complete challenges to see your history here',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _completedChallenges.length,
      itemBuilder: (context, index) => _buildChallengeCard(_completedChallenges[index], isCompleted: true),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, {bool isActive = false, bool isCompleted = false}) {
    final tokens = context.tokens;
    final progress = challenge['userProgress'] ?? 0.0;
    final target = challenge['target'] ?? 1;
    final progressPercent = (progress / target * 100).clamp(0, 100);
    final challengeColor = _getChallengeColor(challenge['type']);

    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: challengeColor,
              child: Icon(_getChallengeIcon(challenge['type']), color: tokens.onBrand),
            ),
            title: Text(
              challenge['title'] ?? 'Unknown Challenge',
              style: context.typo.titleSmall,
            ),
            subtitle: Text(
              challenge['description'] ?? '',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
            trailing: _buildChallengeMenu(challenge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge['participantsCount'] ?? 0} participants',
                      style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                    ),
                    Text(
                      _formatDuration(challenge['duration']),
                      style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                if (isActive || isCompleted) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: tokens.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? tokens.success : challengeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    '${progress.toInt()}/$target ${_getChallengeUnit(challenge['type'])}',
                    style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Row(
              children: [
                if (challenge['isPublic'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                    decoration: BoxDecoration(
                      color: tokens.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Radii.statTile),
                    ),
                    child: Text(
                      'PUBLIC',
                      style: context.typo.label.copyWith(color: tokens.brand),
                    ),
                  ),
                const Spacer(),
                if (!isActive && !isCompleted)
                  ElevatedButton(
                    onPressed: () => _joinChallenge(challenge),
                    child: const Text('Join'),
                  )
                else if (isActive)
                  OutlinedButton(
                    onPressed: () => _leaveChallenge(challenge),
                    child: const Text('Leave'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeMenu(Map<String, dynamic> challenge) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleChallengeAction(value, challenge),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'details', child: Text('View Details')),
        const PopupMenuItem(value: 'leaderboard', child: Text('Leaderboard')),
        if (challenge['isCreator'] == true) ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ] else
          const PopupMenuItem(value: 'report', child: Text('Report')),
      ],
    );
  }

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'workouts';
    int target = 10;
    int duration = 30;
    bool isPublic = true;
    int? maxParticipants;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Space.lg),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: Space.lg),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Challenge Type'),
                  items: const [
                    DropdownMenuItem(value: 'workouts', child: Text('Workouts')),
                    DropdownMenuItem(value: 'steps', child: Text('Steps')),
                    DropdownMenuItem(value: 'distance', child: Text('Distance')),
                    DropdownMenuItem(value: 'calories', child: Text('Calories')),
                    DropdownMenuItem(value: 'weight_loss', child: Text('Weight Loss')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: target.toString(),
                        decoration: const InputDecoration(labelText: 'Target'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => target = int.tryParse(value) ?? target,
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: TextFormField(
                        initialValue: duration.toString(),
                        decoration: const InputDecoration(labelText: 'Duration (days)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => duration = int.tryParse(value) ?? duration,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                SwitchListTile(
                  title: const Text('Public Challenge'),
                  subtitle: const Text('Anyone can join'),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                ),
                if (isPublic)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Max Participants (optional)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => maxParticipants = int.tryParse(value),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _createChallenge(
                titleController.text,
                descriptionController.text,
                selectedType,
                target,
                duration,
                isPublic,
                maxParticipants,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createChallenge(
    String title,
    String description,
    String type,
    int target,
    int duration,
    bool isPublic,
    int? maxParticipants,
  ) async {
    if (title.trim().isEmpty) return;

    Navigator.pop(context);

    try {
      final challenge = await _socialService.createChallenge(
        title: title.trim(),
        description: description.trim(),
        type: type,
        target: target,
        duration: duration,
        isPublic: isPublic,
        maxParticipants: maxParticipants,
      );

      if (challenge != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge created successfully!')),
          );
        }
        _loadChallenges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create challenge')),
        );
      }
    }
  }

  Future<void> _joinChallenge(Map<String, dynamic> challenge) async {
    try {
      final success = await _socialService.joinChallenge(challenge['id']);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined ${challenge['title']}!')),
          );
        }
        _loadChallenges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join challenge')),
        );
      }
    }
  }

  Future<void> _leaveChallenge(Map<String, dynamic> challenge) async {
    try {
      final success = await _socialService.leaveChallenge(challenge['id']);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Left ${challenge['title']}')),
          );
        }
        _loadChallenges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave challenge')),
        );
      }
    }
  }

  void _handleChallengeAction(String action, Map<String, dynamic> challenge) {
    switch (action) {
      case 'details':
        _showChallengeDetails(challenge);
        break;
      case 'leaderboard':
        _showLeaderboard(challenge);
        break;
      case 'edit':
      case 'delete':
      case 'report':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature coming soon!')),
          );
        }
        break;
    }
  }

  void _showChallengeDetails(Map<String, dynamic> challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(challenge['title'] ?? 'Challenge Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge['description'] ?? ''),
            const SizedBox(height: Space.lg),
            Text('Type: ${_getChallengeTypeDisplayName(challenge['type'])}'),
            Text('Target: ${challenge['target']} ${_getChallengeUnit(challenge['type'])}'),
            Text('Duration: ${_formatDuration(challenge['duration'])}'),
            Text('Participants: ${challenge['participantsCount'] ?? 0}'),
            if (challenge['maxParticipants'] != null)
              Text('Max Participants: ${challenge['maxParticipants']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(Map<String, dynamic> challenge) {
    // TODO: Implement leaderboard dialog
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leaderboard feature coming soon!')),
      );
    }
  }

  Color _getChallengeColor(String? type) {
    final tokens = context.tokens;
    switch (type) {
      case 'workouts':
        return _ChallengeColors.workouts;
      case 'steps':
        return tokens.success;
      case 'distance':
        return _ChallengeColors.distance;
      case 'calories':
        return _ChallengeColors.calories;
      case 'weight_loss':
        return _ChallengeColors.weightLoss;
      default:
        return tokens.inkMuted;
    }
  }

  IconData _getChallengeIcon(String? type) {
    switch (type) {
      case 'workouts':
        return Icons.fitness_center;
      case 'steps':
        return Icons.directions_walk;
      case 'distance':
        return Icons.directions_run;
      case 'calories':
        return Icons.local_fire_department;
      case 'weight_loss':
        return Icons.scale;
      default:
        return Icons.emoji_events;
    }
  }

  String _getChallengeUnit(String? type) {
    switch (type) {
      case 'workouts':
        return 'workouts';
      case 'steps':
        return 'steps';
      case 'distance':
        return 'km';
      case 'calories':
        return 'calories';
      case 'weight_loss':
        return 'kg';
      default:
        return '';
    }
  }

  String _getChallengeTypeDisplayName(String? type) {
    switch (type) {
      case 'workouts':
        return 'Workouts';
      case 'steps':
        return 'Steps';
      case 'distance':
        return 'Running Distance';
      case 'calories':
        return 'Calories Burned';
      case 'weight_loss':
        return 'Weight Loss';
      default:
        return 'Unknown';
    }
  }

  String _formatDuration(int? days) {
    if (days == null) return '';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days == 7) return '1 week';
    if (days < 30) return '${(days / 7).round()} weeks';
    if (days == 30) return '1 month';
    return '${(days / 30).round()} months';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
