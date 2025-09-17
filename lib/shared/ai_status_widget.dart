import 'package:flutter/material.dart';
import 'package:trego/shared/api_config.dart';

class AiStatusWidget extends StatelessWidget {
  const AiStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isAiEnabled = ApiConfig.isAiEnabled;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAiSetupDialog(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAiEnabled 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAiEnabled 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isAiEnabled ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
              color: isAiEnabled ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showAiSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ApiConfig.isAiEnabled ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                  color: ApiConfig.isAiEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  ApiConfig.isAiEnabled ? 'AI Assistant Active' : 'AI Assistant Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ApiConfig.isAiEnabled ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ApiConfig.isAiEnabled 
                  ? 'AI-powered recipes and workout plans are available.'
                  : 'To enable AI features, add your OpenAI API key in lib/shared/api_config.dart',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 