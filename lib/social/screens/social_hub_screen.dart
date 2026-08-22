import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/trego_scaffold.dart';
import '../social_service.dart';
import 'challenges_screen.dart';
import 'friends_screen.dart';
import 'social_feed_screen.dart';

/// Social hub — the canonical Feed tab destination. Hosts Feed, Friends, and
/// Challenges under one tabbed roof, embedding the existing screens
/// unchanged. Replaces the old orphan `lib/social/social_hub.dart`.
class SocialHubScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [SocialService].
  final SocialService? service;

  /// Which tab to open on: 0 = Feed, 1 = Friends, 2 = Challenges.
  final int initialTab;

  /// Which sub-tab the embedded [FriendsScreen] opens on: 0 = Friends,
  /// 1 = Requests. Only relevant when [initialTab] is 1.
  final int friendsInitialTab;

  /// Optional key placed on the embedded [SocialFeedScreen], so callers
  /// (e.g. the app shell) can imperatively `.reload()` the feed.
  final GlobalKey<SocialFeedScreenState>? feedKey;

  const SocialHubScreen({
    super.key,
    this.service,
    this.initialTab = 0,
    this.friendsInitialTab = 0,
    this.feedKey,
  });

  @override
  State<SocialHubScreen> createState() => SocialHubScreenState();
}

class SocialHubScreenState extends State<SocialHubScreen> with SingleTickerProviderStateMixin {
  late final GlobalKey<SocialFeedScreenState> _feedKey = widget.feedKey ?? GlobalKey<SocialFeedScreenState>();
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 2),
  );

  /// Re-fetch the feed. Called by the shell when the Feed tab is (re)selected.
  void reloadFeed() => _feedKey.currentState?.reload();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56 + 48),
        child: Material(
          color: tokens.surfaceSunken,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Social', style: context.typo.title),
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: tokens.brand,
                  unselectedLabelColor: tokens.inkMuted,
                  indicatorColor: tokens.brand,
                  tabs: const [
                    Tab(text: 'Feed'),
                    Tab(text: 'Friends'),
                    Tab(text: 'Challenges'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SocialFeedScreen(key: _feedKey, service: widget.service),
          FriendsScreen(service: widget.service, initialTab: widget.friendsInitialTab),
          const ChallengesScreen(),
        ],
      ),
    );
  }
}
