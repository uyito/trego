import 'package:flutter/material.dart';
import '../recipes/recipe_screen.dart';
import '../shared/pantry_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../tdee/tdee_screen.dart';
import '../widgets/core/trego_scaffold.dart';

/// Nutrition hub — replaces the dead Plan tab. Hosts Recipes, Pantry, and
/// TDEE under one tabbed roof, embedding the existing screens unchanged.
class NutritionHub extends StatelessWidget {
  const NutritionHub({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DefaultTabController(
      length: 3,
      child: TregoScaffold(
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
                            child: Text('Nutrition', style: context.typo.title),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TabBar(
                    labelColor: tokens.brand,
                    unselectedLabelColor: tokens.inkMuted,
                    indicatorColor: tokens.brand,
                    tabs: const [
                      Tab(text: 'Recipes'),
                      Tab(text: 'Pantry'),
                      Tab(text: 'TDEE'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            RecipeScreen(),
            _PantryTab(),
            TdeeScreen(),
          ],
        ),
      ),
    );
  }
}

/// Lightweight token-styled pantry list backed by the existing
/// [PantryService]. No standalone pantry screen exists yet in lib/recipes,
/// so this is a real (not "coming soon") v1 list view.
class _PantryTab extends StatefulWidget {
  const _PantryTab();

  @override
  State<_PantryTab> createState() => _PantryTabState();
}

class _PantryTabState extends State<_PantryTab> {
  final PantryService _pantryService = PantryService();
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _pantryService.getPantryItems();
  }

  Future<void> _reload() async {
    setState(() {
      _itemsFuture = _pantryService.getPantryItems();
    });
    await _itemsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? const [];

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.xxl),
                  child: Column(
                    children: [
                      Icon(Icons.kitchen_outlined, size: 48, color: tokens.inkMuted),
                      const SizedBox(height: Space.md),
                      Text('Your pantry is empty', style: context.typo.title),
                      const SizedBox(height: Space.sm),
                      Text(
                        'Items you add to your pantry will show up here.',
                        textAlign: TextAlign.center,
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name']?.toString() ?? 'Item';
              final quantity = item['quantity'];
              final unit = item['unit']?.toString();
              final subtitleParts = <String>[
                if (quantity != null) quantity.toString(),
                if (unit != null && unit.isNotEmpty) unit,
              ];
              return Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(Radii.standardCard),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: tokens.inkMuted),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: context.typo.body),
                          if (subtitleParts.isNotEmpty)
                            Text(
                              subtitleParts.join(' '),
                              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
