import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_flutter/config/gemini_config.dart';
import '../models/recipe.dart';

class GeminiService {
  static const String apiKey = GeminiConfig.apiKey;
  // UPDATED: Using Gemini 2.5 Flash
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';


  /// Generate recipe recommendations with scores based on user profile and pantry
  static Future<List<RecipeRecommendation>> getRecipeRecommendations({
    // 3 inputs: user data, pantry items, and recipes
    // Returns a list of scored recommendations
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> pantryItems,
    required List<Recipe> recipes,
  }) async {
    // Reduced batch size to avoid MAX_TOKENS with thinking tokens
    const maxRecipesPerBatch = 4;

    if (recipes.length <= maxRecipesPerBatch) {
      // If we have 4 or fewer recipes, process them all at once
      return _getRecommendationsBatch(userData, pantryItems, recipes);
    }

    // Process in batches for larger lists
    List<RecipeRecommendation> allRecommendations = [];
    for (int i = 0; i < recipes.length; i += maxRecipesPerBatch) {
      final batch = recipes.skip(i).take(maxRecipesPerBatch).toList();
      print('📦 Processing batch ${(i ~/ maxRecipesPerBatch) + 1} (${batch.length} recipes)');

      final batchResults = await _getRecommendationsBatch(userData, pantryItems, batch);
      allRecommendations.addAll(batchResults);

      // Small delay between batches to avoid rate limits
      if (i + maxRecipesPerBatch < recipes.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Sort all results by score
    allRecommendations.sort((a, b) => b.score.compareTo(a.score));
    return allRecommendations;
  }

  /// Process a single batch of recipes
  static Future<List<RecipeRecommendation>> _getRecommendationsBatch(
      Map<String, dynamic> userData,
      List<Map<String, dynamic>> pantryItems,
      List<Recipe> recipes,
      ) async {
    try {
      // Build the prompt
      final prompt = _buildPrompt(userData, pantryItems, recipes);

      // Call Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 4096, // Increased from 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug: Log token usage
        if (data['usageMetadata'] != null) {
          final usage = data['usageMetadata'];
          print('🔢 Tokens - Input: ${usage['promptTokenCount']}, Output: ${usage['candidatesTokenCount']}, Thinking: ${usage['thoughtsTokenCount'] ?? 0}');
        }
        // Get the AI's text response
        // Check if response has the expected structure
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          print('❌ Error: No candidates in response');
          throw Exception('No candidates in Gemini response');
        }

        final candidate = data['candidates'][0];

        // Check for MAX_TOKENS issue
        if (candidate['finishReason'] == 'MAX_TOKENS') {
          print('⚠️ Warning: Response hit MAX_TOKENS limit');
          print('Prompt was too long. Using fallback for this batch.');
          throw Exception('MAX_TOKENS limit reached');
        }

        if (candidate['content'] == null || candidate['content']['parts'] == null) {
          print('❌ Error: Invalid response structure');
          throw Exception('Invalid Gemini response structure');
        }

        final text = candidate['content']['parts'][0]['text'];
        print('✅ Got ${recipes.length} recipe recommendations (${text.length} chars)');

        // Parse the response
        return _parseGeminiResponse(text, recipes);
      } else {
        print('❌ Gemini API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getRecipeRecommendations: $e');
      print('Stack trace: ${StackTrace.current}');

      // Return fallback recommendations instead of throwing
      print('⚠️ Returning fallback recommendations');
      return _getFallbackRecommendations(recipes, userData, pantryItems);
    }
  }

  /// Build the prompt for Gemini
  static String _buildPrompt(
      Map<String, dynamic> userData,
      List<Map<String, dynamic>> pantryItems,
      List<Recipe> recipes,
      ) {
    final allergies = (userData['allergies'] as List?)?.join(', ') ?? 'none';
    final dietType = userData['dietType'] ?? 'None';
    final goal = userData['goal'] ?? 'Maintain';

    // Only include first 5 pantry items to save tokens
    final pantryIngredients = pantryItems
        .take(5)
        .map((item) => item['ingredient'])
        .join(',');

    // Formatting recipes for AI
    final recipeList = recipes.map((recipe) {
      // Get first 6 ingredients (save tokens)
      final ingredientNames = recipe.ingredients
          ?.map((ing) => ing.name)
          .take(6) // Reduced from 8 to 6
          .join(',') ?? 'unknown';

      // Format: ID|Name|Calories|Ingredients
      return '${recipe.id}|${recipe.name}|${recipe.calories}|$ingredientNames';
    }).join('\n');

    // The Actual Prompt
    return '''
Score these recipes 0-100 for user. Return JSON array only, no markdown.

USER: Allergy=$allergies Diet=$dietType Goal=$goal Pantry=$pantryIngredients

RECIPES:
$recipeList

RULES: Allergen=0, Diet fit+30, Goal fit+25, Pantry+20, Nutrition+15, Easy+10

JSON: [{"recipeId":"123","score":85,"recommendation":"reason"}]
All ${recipes.length} recipes required.''';
  }

  /// Parse Gemini response into RecipeRecommendation objects
  static List<RecipeRecommendation> _parseGeminiResponse(
      String responseText,
      List<Recipe> originalRecipes,
      ) {
    try {
      // Clean the response - remove markdown code blocks if present
      String cleanedText = responseText.trim();
      // AI sometimes wraps JSON in ```json ... ```
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);// Remove ```json
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      // Parse JSON
      // Convert string to JSON array
      final List<dynamic> jsonList = jsonDecode(cleanedText);

      List<RecipeRecommendation> recommendations = [];

      for (var item in jsonList) {
        // Extract fields
        final recipeId = item['recipeId'].toString();
        final score = (item['score'] as num).toInt();
        final recommendation = item['recommendation'] as String;

        // Find the original recipe
        final recipe = originalRecipes.firstWhere(
              (r) => r.id == recipeId,
          orElse: () => originalRecipes.first, // Fallback
        );
        // Create recommendation object
        recommendations.add(RecipeRecommendation(
          recipe: recipe,
          score: score,
          recommendation: recommendation,
        ));
      }

      // Sort by score (highest first)
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations;

      // Fallback System (Système de repli)
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      print('Response text: $responseText');

      // Fallback: return recipes with default scores
      // // If AI fails, use simple fallback scoring
      return originalRecipes.map((recipe) {
        return RecipeRecommendation(
          recipe: recipe,
          score: 50,
          recommendation: 'Unable to generate AI recommendation. Default scoring applied.',
        );
      }).toList();
    }
  }

  /// Quick check if a recipe is safe for user allergies
  static bool isRecipeSafe(Recipe recipe, List<String> userAllergies) {
    if (userAllergies.isEmpty || recipe.ingredients == null) return true;

    final ingredientNames = recipe.ingredients!
        .map((ing) => ing.name.toLowerCase())
        .toList();

    // Simple allergen detection
    final allergenKeywords = {
      'dairy': ['milk', 'cheese', 'butter', 'cream', 'yogurt'],
      'gluten': ['flour', 'wheat', 'bread', 'pasta'],
      'nuts': ['almond', 'walnut', 'peanut', 'cashew'],
      'eggs': ['egg'],
      'soy': ['soy', 'tofu'],
      'shellfish': ['shrimp', 'crab', 'lobster'],
    };

    for (var allergy in userAllergies) {
      final keywords = allergenKeywords[allergy.toLowerCase()] ?? [];
      for (var keyword in keywords) {
        if (ingredientNames.any((ing) => ing.contains(keyword))) {
          return false;
        }
      }
    }

    return true;
  }

  /// Fallback recommendations strategy when AI fails
  static List<RecipeRecommendation> _getFallbackRecommendations(
      List<Recipe> recipes,
      Map<String, dynamic> userData,
      List<Map<String, dynamic>> pantryItems,
      ) {
    final userAllergies = (userData['allergies'] as List?)?.cast<String>() ?? [];

    return recipes.map((recipe) {
      // Check for allergens
      if (!isRecipeSafe(recipe, userAllergies)) {
        return RecipeRecommendation(
          recipe: recipe,
          score: 0,
          recommendation: '❌ Contains allergen. Not safe for your profile.',
        );
      }

      // Simple scoring based on available data
      int score = 50; // Base score
      String reason = 'Standard recommendation';

      // Adjust based on calories and goal
      final goal = userData['goal'] as String?;
      final calories = recipe.calories ?? 0;

      if (goal == 'Lose Weight' && calories < 400) {
        score += 20;
        reason = 'Low calorie option suitable for weight loss.';
      } else if (goal == 'Gain Weight' && calories > 600) {
        score += 20;
        reason = 'High calorie option suitable for gaining weight.';
      } else if (goal == 'Maintain Weight' && calories >= 400 && calories <= 600) {
        score += 15;
        reason = 'Balanced calorie content for maintenance.';
      }

      // Random variation for variety
      score += (recipe.id.hashCode % 20) - 10;
      score = score.clamp(10, 100);

      return RecipeRecommendation(
        recipe: recipe,
        score: score,
        recommendation: reason,
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }
}

/// Model for recipe recommendation with score
class RecipeRecommendation {
  final Recipe recipe;
  final int score;
  final String recommendation;

  RecipeRecommendation({
    required this.recipe,
    required this.score,
    required this.recommendation,
  });

  bool get isSafe => score > 0;
  bool get isHighlyRecommended => score >= 80;
  bool get isRecommended => score >= 60;
  bool get isModeratelyRecommended => score >= 40;

  String get scoreLabel {
    if (score == 0) return '❌ Not Safe';
    if (score >= 80) return '⭐ Highly Recommended';
    if (score >= 60) return '✅ Recommended';
    if (score >= 40) return '👌 Good Option';
    return '🤔 Consider Alternatives';
  }

  Color get scoreColor {
    if (score == 0) return Colors.red;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.grey;
  }
}