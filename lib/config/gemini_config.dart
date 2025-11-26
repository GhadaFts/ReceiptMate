
class GeminiConfig {

  static const String apiKey = 'AIzaSyCSnbsOfuYPfPTCXNuay2OolQKcqTrDXNo';

  static const String modelName = 'gemini-2.5-flash';
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Generation parameters
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 2048;
}