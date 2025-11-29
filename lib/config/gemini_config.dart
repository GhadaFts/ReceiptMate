
class GeminiConfig {
  // Google Gemini API Key
  static const String apiKey = 'AIzaSyCSnbsOfuYPfPTCXNuay2OolQKcqTrDXNo';

  // modal to use
  static const String modelName = 'gemini-2.5-flash';

  // Base URL for Gemini API
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Generation parameters control
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 2048;
}