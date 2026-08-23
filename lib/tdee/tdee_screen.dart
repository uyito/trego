import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_scaffold.dart';

/// Semantic result colors for BMR / TDEE / recommended-calorie cards. These
/// are distinct decorative hues (not brand/danger/success roles), so they're
/// centralized here as named consts rather than scattered raw hex.
class _TdeeResultColors {
  static const bmr = Color(0xFFF57C00); // ALLOW-HEX: BMR result accent (orange), no token role fits a decorative per-metric hue
  static const tdee = Color(0xFF1E88E5); // ALLOW-HEX: TDEE result accent (blue), no token role fits a decorative per-metric hue
  static const recommended = Color(0xFF00A344); // ALLOW-HEX: recommended-calories accent, matches tokens.success light value intentionally kept as const for card use outside ThemeExtension access
  _TdeeResultColors._();
}

class TdeeScreen extends StatefulWidget {
  const TdeeScreen({super.key});

  @override
  State<TdeeScreen> createState() => _TdeeScreenState();
}

class _TdeeScreenState extends State<TdeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();

  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  String _goal = 'Maintain Weight';
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';

  double? _bmr;
  double? _tdee;
  double? _suggestedCalories;
  bool _isLoading = false;
  bool _showResult = false;

  static const activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extra Active': 1.9,
  };

  static const goalMultipliers = {
    'Lose Weight': 0.85,
    'Maintain Weight': 1.0,
    'Gain Muscle': 1.1,
  };

  Future<void> _calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _showResult = false;
    });

    final int age = int.parse(_ageController.text);

    // Convert weight to kg if needed
    double weightKg = double.parse(_weightController.text);
    if (_weightUnit == 'lbs') {
      weightKg = weightKg * 0.453592; // Convert lbs to kg
    }

    // Convert height to cm if needed
    double heightCm;
    if (_heightUnit == 'cm') {
      heightCm = double.parse(_heightController.text);
    } else {
      // Convert feet and inches to cm
      final feet = int.parse(_heightFeetController.text);
      final inches = int.parse(_heightInchesController.text);
      heightCm = (feet * 30.48) + (inches * 2.54); // Convert ft/in to cm
    }

    double bmr;
    if (_gender == 'Male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
    final double tdee = bmr * activityMultipliers[_activityLevel]!;
    final double suggested = tdee * goalMultipliers[_goal]!;
    setState(() {
      _bmr = bmr;
      _tdee = tdee;
      _suggestedCalories = suggested;
      _showResult = true;
    });
    // Save to Firestore
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tdee')
            .add({
          'age': age,
          'gender': _gender,
          'height': heightCm,
          'weight': weightKg,
          'activityLevel': _activityLevel,
          'goal': _goal,
          'bmr': bmr,
          'tdee': tdee,
          'suggestedCalories': suggested,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: tokens.danger,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(Space.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tokens.brandContainerStart,
                        tokens.brandContainerEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Radii.screenWrapper),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.brand.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TDEE Calculator',
                                  style: context.typo.title.copyWith(
                                    color: tokens.onBrand,
                                  ),
                                ),
                                const SizedBox(height: Space.xs),
                                Text(
                                  'Calculate your daily calorie needs',
                                  style: context.typo.body.copyWith(
                                    color: tokens.onBrand.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(Space.md),
                            decoration: BoxDecoration(
                              color: tokens.onBrand.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(Radii.statTile),
                            ),
                            child: Icon(
                              Icons.calculate_rounded,
                              color: tokens.onBrand,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xl),

                // Form Fields
                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.person_rounded,
                  title: 'Age',
                  subtitle: 'Enter your current age',
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: context.typo.body,
                    decoration: InputDecoration(
                      hintText: 'Enter your age',
                      hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: tokens.brand,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter your age';
                      final n = int.tryParse(value);
                      if (n == null || n < 10 || n > 120) return 'Enter a valid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: Space.lg),

                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.wc_rounded,
                  title: 'Gender',
                  subtitle: 'Select your biological gender',
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    style: context.typo.body,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.wc_rounded,
                        color: tokens.brand,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _gender = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: Space.lg),

                // Height Card
                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.height_rounded,
                  title: 'Height',
                  subtitle: 'Toggle between centimeters and feet/inches',
                  child: Column(
                    children: [
                      // Height Unit Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSunken,
                          borderRadius: BorderRadius.circular(Radii.statTile),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _heightUnit = 'cm';
                                    _heightController.clear();
                                    _heightFeetController.clear();
                                    _heightInchesController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.lg),
                                  decoration: BoxDecoration(
                                    color: _heightUnit == 'cm'
                                        ? tokens.brand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Radii.button),
                                  ),
                                  child: Text(
                                    'Centimeters (cm)',
                                    textAlign: TextAlign.center,
                                    style: context.typo.bodySmall.copyWith(
                                      color: _heightUnit == 'cm'
                                          ? tokens.onBrand
                                          : tokens.inkMuted,
                                      fontWeight: _heightUnit == 'cm'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _heightUnit = 'ft';
                                    _heightController.clear();
                                    _heightFeetController.clear();
                                    _heightInchesController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.lg),
                                  decoration: BoxDecoration(
                                    color: _heightUnit == 'ft'
                                        ? tokens.brand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Radii.button),
                                  ),
                                  child: Text(
                                    'Feet & Inches',
                                    textAlign: TextAlign.center,
                                    style: context.typo.bodySmall.copyWith(
                                      color: _heightUnit == 'ft'
                                          ? tokens.onBrand
                                          : tokens.inkMuted,
                                      fontWeight: _heightUnit == 'ft'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),

                      // Height Input
                      _heightUnit == 'cm'
                          ? TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              style: context.typo.body,
                              decoration: InputDecoration(
                                hintText: 'Enter height in cm',
                                hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                                suffixText: 'cm',
                                prefixIcon: Icon(
                                  Icons.height_rounded,
                                  color: tokens.brand,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter your height';
                                final n = double.tryParse(value);
                                if (n == null || n < 100 || n > 250) return 'Enter a valid height';
                                return null;
                              },
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightFeetController,
                                    keyboardType: TextInputType.number,
                                    style: context.typo.body,
                                    decoration: InputDecoration(
                                      hintText: 'Feet',
                                      hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                                      suffixText: 'ft',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter feet';
                                      final n = int.tryParse(value);
                                      if (n == null || n < 3 || n > 8) return 'Enter valid feet';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: Space.lg),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightInchesController,
                                    keyboardType: TextInputType.number,
                                    style: context.typo.body,
                                    decoration: InputDecoration(
                                      hintText: 'Inches',
                                      hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                                      suffixText: 'in',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter inches';
                                      final n = int.tryParse(value);
                                      if (n == null || n < 0 || n > 11) return 'Enter valid inches';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),

                // Weight Card
                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.monitor_weight_rounded,
                  title: 'Weight',
                  subtitle: 'Toggle between kilograms and pounds',
                  child: Column(
                    children: [
                      // Weight Unit Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSunken,
                          borderRadius: BorderRadius.circular(Radii.statTile),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _weightUnit = 'kg';
                                    _weightController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.lg),
                                  decoration: BoxDecoration(
                                    color: _weightUnit == 'kg'
                                        ? tokens.brand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Radii.button),
                                  ),
                                  child: Text(
                                    'Kilograms (kg)',
                                    textAlign: TextAlign.center,
                                    style: context.typo.bodySmall.copyWith(
                                      color: _weightUnit == 'kg'
                                          ? tokens.onBrand
                                          : tokens.inkMuted,
                                      fontWeight: _weightUnit == 'kg'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _weightUnit = 'lbs';
                                    _weightController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.lg),
                                  decoration: BoxDecoration(
                                    color: _weightUnit == 'lbs'
                                        ? tokens.brand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Radii.button),
                                  ),
                                  child: Text(
                                    'Pounds (lbs)',
                                    textAlign: TextAlign.center,
                                    style: context.typo.bodySmall.copyWith(
                                      color: _weightUnit == 'lbs'
                                          ? tokens.onBrand
                                          : tokens.inkMuted,
                                      fontWeight: _weightUnit == 'lbs'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),

                      // Weight Input
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: context.typo.body,
                        decoration: InputDecoration(
                          hintText: 'Enter weight in ${_weightUnit}',
                          hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                          suffixText: _weightUnit,
                          prefixIcon: Icon(
                            Icons.monitor_weight_rounded,
                            color: tokens.brand,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter your weight';
                          final n = double.tryParse(value);
                          if (n == null) return 'Enter a valid weight';
                          if (_weightUnit == 'kg' && (n < 30 || n > 300)) {
                            return 'Enter a valid weight (30-300 kg)';
                          }
                          if (_weightUnit == 'lbs' && (n < 66 || n > 660)) {
                            return 'Enter a valid weight (66-660 lbs)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),

                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.directions_run_rounded,
                  title: 'Activity Level',
                  subtitle: 'How active are you on a daily basis?',
                  child: DropdownButtonFormField<String>(
                    value: _activityLevel,
                    style: context.typo.body,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.directions_run_rounded,
                        color: tokens.brand,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary')),
                      DropdownMenuItem(value: 'Lightly Active', child: Text('Lightly Active')),
                      DropdownMenuItem(value: 'Moderately Active', child: Text('Moderately Active')),
                      DropdownMenuItem(value: 'Very Active', child: Text('Very Active')),
                      DropdownMenuItem(value: 'Extra Active', child: Text('Extra Active')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _activityLevel = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: Space.lg),

                _buildEnhancedFormField(
                  context: context,
                  icon: Icons.flag_rounded,
                  title: 'Goal',
                  subtitle: 'What is your fitness goal?',
                  child: DropdownButtonFormField<String>(
                    value: _goal,
                    style: context.typo.body,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.flag_rounded,
                        color: tokens.brand,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Lose Weight', child: Text('Lose Weight')),
                      DropdownMenuItem(value: 'Maintain Weight', child: Text('Maintain Weight')),
                      DropdownMenuItem(value: 'Gain Muscle', child: Text('Gain Muscle')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _goal = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: Space.xxl),

                // Calculate Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _calculateAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.brand,
                      foregroundColor: tokens.onBrand,
                      elevation: 3,
                      shadowColor: tokens.brand.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.button),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(tokens.onBrand),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calculate_rounded),
                              const SizedBox(width: Space.sm),
                              Text(
                                'Calculate TDEE',
                                style: context.typo.title.copyWith(color: tokens.onBrand),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: Space.xl),

                // Results
                if (_showResult && _bmr != null && _tdee != null && _suggestedCalories != null)
                  Container(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(Radii.standardCard),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(Space.md),
                                decoration: BoxDecoration(
                                  color: _TdeeResultColors.recommended.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Radii.statTile),
                                ),
                                child: Icon(
                                  Icons.insights_rounded,
                                  color: _TdeeResultColors.recommended,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: Space.lg),
                              Text(
                                'Your Results',
                                style: context.typo.title,
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.xl),
                          _buildResultCard(
                            context: context,
                            icon: Icons.local_fire_department_rounded,
                            title: 'BMR (Basal Metabolic Rate)',
                            value: '${_bmr!.toStringAsFixed(0)} kcal',
                            subtitle: 'Calories burned at rest',
                            color: _TdeeResultColors.bmr,
                          ),
                          const SizedBox(height: Space.md),
                          _buildResultCard(
                            context: context,
                            icon: Icons.trending_up_rounded,
                            title: 'TDEE (Total Daily Energy Expenditure)',
                            value: '${_tdee!.toStringAsFixed(0)} kcal',
                            subtitle: 'Total daily calorie needs',
                            color: _TdeeResultColors.tdee,
                          ),
                          const SizedBox(height: Space.md),
                          _buildResultCard(
                            context: context,
                            icon: Icons.recommend_rounded,
                            title: 'Recommended Calories',
                            value: '${_suggestedCalories!.toStringAsFixed(0)} kcal',
                            subtitle: 'Based on your goal',
                            color: _TdeeResultColors.recommended,
                          ),
                          const SizedBox(height: Space.xl),

                          // Unit conversion display
                          Container(
                            padding: const EdgeInsets.all(Space.lg),
                            decoration: BoxDecoration(
                              color: tokens.surfaceSunken,
                              borderRadius: BorderRadius.circular(Radii.statTile),
                              border: Border.all(color: tokens.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Conversions',
                                  style: context.typo.titleSmall,
                                ),
                                const SizedBox(height: Space.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildConversionItem(
                                        context,
                                        'Weight',
                                        '${(double.parse(_weightController.text) * (_weightUnit == 'lbs' ? 0.453592 : 1)).toStringAsFixed(1)} kg',
                                        '${(double.parse(_weightController.text) * (_weightUnit == 'kg' ? 2.20462 : 1)).toStringAsFixed(1)} lbs',
                                      ),
                                    ),
                                    const SizedBox(width: Space.lg),
                                    Expanded(
                                      child: _buildConversionItem(
                                        context,
                                        'Height',
                                        '${_heightUnit == 'cm' ? double.parse(_heightController.text).toStringAsFixed(1) : ((int.parse(_heightFeetController.text) * 30.48) + (int.parse(_heightInchesController.text) * 2.54)).toStringAsFixed(1)} cm',
                                        '${_heightUnit == 'ft' ? '${_heightFeetController.text}\'${_heightInchesController.text}"' : '${(double.parse(_heightController.text) / 30.48).floor()}\'${((double.parse(_heightController.text) % 30.48) / 2.54).round()}"'}',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Space.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFormField({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(Radii.standardCard),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: tokens.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.statTile),
                  ),
                  child: Icon(
                    icon,
                    color: tokens.brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.typo.titleSmall,
                      ),
                      Text(
                        subtitle,
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.statTile),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Icon(
              icon,
              color: tokens.onBrand,
              size: 20,
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typo.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: context.typo.titleSmall.copyWith(
                    fontSize: 18,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.typo.bodySmall.copyWith(color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionItem(BuildContext context, String label, String metricValue, String imperialValue) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typo.bodySmall.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
        ),
        const SizedBox(height: Space.xs),
        Text(
          metricValue,
          style: context.typo.titleSmall.copyWith(color: _TdeeResultColors.tdee),
        ),
        Text(
          imperialValue,
          style: context.typo.titleSmall.copyWith(color: _TdeeResultColors.bmr),
        ),
      ],
    );
  }
}
