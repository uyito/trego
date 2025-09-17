import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: Colors.red,
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Calculate your daily calorie needs',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calculate_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  _buildEnhancedFormField(
                    context: context,
                    icon: Icons.person_rounded,
                    title: 'Age',
                    subtitle: 'Enter your current age',
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter your age',
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 20),

                  _buildEnhancedFormField(
                    context: context,
                    icon: Icons.wc_rounded,
                    title: 'Gender',
                    subtitle: 'Select your biological gender',
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.wc_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 20),

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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _heightUnit == 'cm' 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Centimeters (cm)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _heightUnit == 'cm' 
                                            ? Colors.white 
                                            : Colors.grey[600],
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _heightUnit == 'ft' 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Feet & Inches',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _heightUnit == 'ft' 
                                            ? Colors.white 
                                            : Colors.grey[600],
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
                        const SizedBox(height: 16),

                        // Height Input
                        _heightUnit == 'cm'
                            ? TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter height in cm',
                                  suffixText: 'cm',
                                  prefixIcon: Icon(
                                    Icons.height_rounded,
                                    color: Theme.of(context).colorScheme.primary,
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
                                      decoration: const InputDecoration(
                                        hintText: 'Feet',
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightInchesController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Inches',
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
                  const SizedBox(height: 20),

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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _weightUnit == 'kg' 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Kilograms (kg)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _weightUnit == 'kg' 
                                            ? Colors.white 
                                            : Colors.grey[600],
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _weightUnit == 'lbs' 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Pounds (lbs)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _weightUnit == 'lbs' 
                                            ? Colors.white 
                                            : Colors.grey[600],
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
                        const SizedBox(height: 16),

                        // Weight Input
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter weight in ${_weightUnit}',
                            suffixText: _weightUnit,
                            prefixIcon: Icon(
                              Icons.monitor_weight_rounded,
                              color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 20),

                  _buildEnhancedFormField(
                    context: context,
                    icon: Icons.directions_run_rounded,
                    title: 'Activity Level',
                    subtitle: 'How active are you on a daily basis?',
                    child: DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.directions_run_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 20),

                  _buildEnhancedFormField(
                    context: context,
                    icon: Icons.flag_rounded,
                    title: 'Goal',
                    subtitle: 'What is your fitness goal?',
                    child: DropdownButtonFormField<String>(
                      value: _goal,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.flag_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 32),

                  // Calculate Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _calculateAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calculate_rounded),
                                const SizedBox(width: 8),
                                const Text(
                                  'Calculate TDEE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Results
                  if (_showResult && _bmr != null && _tdee != null && _suggestedCalories != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.insights_rounded,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Your Results',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildResultCard(
                              context: context,
                              icon: Icons.local_fire_department_rounded,
                              title: 'BMR (Basal Metabolic Rate)',
                              value: '${_bmr!.toStringAsFixed(0)} kcal',
                              subtitle: 'Calories burned at rest',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildResultCard(
                              context: context,
                              icon: Icons.trending_up_rounded,
                              title: 'TDEE (Total Daily Energy Expenditure)',
                              value: '${_tdee!.toStringAsFixed(0)} kcal',
                              subtitle: 'Total daily calorie needs',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildResultCard(
                              context: context,
                              icon: Icons.recommend_rounded,
                              title: 'Recommended Calories',
                              value: '${_suggestedCalories!.toStringAsFixed(0)} kcal',
                              subtitle: 'Based on your goal',
                              color: Colors.green,
                            ),
                            const SizedBox(height: 20),
                            
                            // Unit conversion display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unit Conversions',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildConversionItem(
                                          'Weight',
                                          '${(double.parse(_weightController.text) * (_weightUnit == 'lbs' ? 0.453592 : 1)).toStringAsFixed(1)} kg',
                                          '${(double.parse(_weightController.text) * (_weightUnit == 'kg' ? 2.20462 : 1)).toStringAsFixed(1)} lbs',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildConversionItem(
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
                  const SizedBox(height: 20),
                ],
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionItem(String label, String metricValue, String imperialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metricValue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          imperialValue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
} 