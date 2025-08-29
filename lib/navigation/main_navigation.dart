import 'package:flutter/material.dart';
import 'package:trego/tracker/tracker_dashboard_screen.dart';
import 'package:trego/workouts/workout_plan_screen.dart';
import 'package:trego/recipes/recipe_screen.dart';
import 'package:trego/tdee/tdee_screen.dart';
import 'package:trego/achievements/achievements_screen.dart';
import 'package:trego/profile/profile_screen.dart';
import 'package:trego/notifications/notifications_screen.dart';
import 'package:trego/profile/profile_screen.dart';
import 'package:trego/achievements/achievements_screen.dart';
import 'package:trego/shared/top_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const List<Widget> _screens = <Widget>[
    TrackerDashboardScreen(),
    WorkoutPlanScreen(),
    RecipeScreen(),
    TdeeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex == 0)
              TopBar(
                currentIndex: _selectedIndex,
                onProfileTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  );
                },
                onNotificationsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen()),
                  );
                },
                onAchievementsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AchievementsScreen()),
                  );
                },
              ),
            // Main Content
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.fitness_center_rounded,
                  activeIcon: Icons.fitness_center,
                  label: 'Workouts',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.restaurant_rounded,
                  activeIcon: Icons.restaurant,
                  label: 'Recipes',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.calculate_rounded,
                  activeIcon: Icons.calculate,
                  label: 'TDEE',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? const Color(0xFFE31E24).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 22 : 20,
                color: isSelected 
                    ? const Color(0xFFE31E24)
                    : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 9 : 8,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFFE31E24)
                    : const Color(0xFF999999),
                letterSpacing: isSelected ? 0.2 : 0.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
} 