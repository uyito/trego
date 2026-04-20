import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';

class TregoScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNav;

  const TregoScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNav,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNav,
    );
  }
}
