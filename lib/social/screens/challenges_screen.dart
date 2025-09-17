import 'package:flutter/material.dart';
import '../social_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateChallengeDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No active challenges', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Join a challenge to get started!'),
            const SizedBox(height: 24),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No available challenges', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Create your own challenge!'),
            const SizedBox(height: 24),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No completed challenges'),
            Text('Complete challenges to see your history here'),
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
    final progress = challenge['userProgress'] ?? 0.0;
    final target = challenge['target'] ?? 1;
    final progressPercent = (progress / target * 100).clamp(0, 100);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getChallengeColor(challenge['type']),
              child: Icon(_getChallengeIcon(challenge['type']), color: Colors.white),
            ),
            title: Text(
              challenge['title'] ?? 'Unknown Challenge',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(challenge['description'] ?? ''),
            trailing: _buildChallengeMenu(challenge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge['participantsCount'] ?? 0} participants',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(challenge['duration']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isActive || isCompleted) ...[
                  LinearProgressIndicator(
                    value: progressPercent / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : _getChallengeColor(challenge['type']),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.toInt()}/$target ${_getChallengeUnit(challenge['type'])}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (challenge['isPublic'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PUBLIC',
                      style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                    const SizedBox(width: 16),
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
                const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
    switch (type) {
      case 'workouts':
        return Colors.blue;
      case 'steps':
        return Colors.green;
      case 'distance':
        return Colors.orange;
      case 'calories':
        return Colors.red;
      case 'weight_loss':
        return Colors.purple;
      default:
        return Colors.grey;
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