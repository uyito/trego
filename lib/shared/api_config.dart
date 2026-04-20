// API Configuration
// This file contains API keys and configuration settings
// For production, use environment variables or Firebase Remote Config

class ApiConfig {
  // OpenAI Configuration
  //
  // DO NOT hardcode real API keys here. Supply via build-time define:
  //   flutter run --dart-define=OPENAI_API_KEY=sk-...
  // Or better: proxy OpenAI calls through the backend so the key never
  // ships in the client bundle.
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'your-openai-api-key-here',
  );
  static const String openaiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String openaiModel = 'gpt-3.5-turbo';
  
  // API Settings
  static const double temperature = 0.7;
  static const int maxTokens = 1000;
  
  // Feature Flags
  static const bool enableAiRecipes = true;
  static const bool enableAiWorkouts = true;
  static const bool enableAiNutrition = false; // Future feature
  static const bool enableAiProgressAnalysis = false; // Future feature
  
  // Check if AI features are enabled and API key is configured
  static bool get isAiEnabled => 
    (enableAiRecipes || enableAiWorkouts || enableAiNutrition || enableAiProgressAnalysis) &&
    openaiApiKey != 'your-openai-api-key-here';
    
  static bool get isRecipeAiEnabled => enableAiRecipes && openaiApiKey != 'your-openai-api-key-here';
  static bool get isWorkoutAiEnabled => enableAiWorkouts && openaiApiKey != 'your-openai-api-key-here';
} 