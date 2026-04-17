import 'package:flutter/material.dart';
import 'screens/social_feed_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/challenges_screen.dart';

class SocialHub extends StatefulWidget {
  const SocialHub({super.key});

  @override
  State<SocialHub> createState() => _SocialHubState();
}

class _SocialHubState extends State<SocialHub> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.feed),
              text: 'Feed',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Friends',
            ),
            Tab(
              icon: Icon(Icons.emoji_events),
              text: 'Challenges',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SocialFeedScreen(),
          FriendsScreen(),
          ChallengesScreen(),
        ],
      ),
    );
  }
}