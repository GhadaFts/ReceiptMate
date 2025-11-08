import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Recherche de recettes par nom
  static Future<List<Recipe>> searchRecipes({
    String query = '',
    int number = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search.php?s=$query');

      print('Fetching recipes from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['meals'] == null) {
          print('No meals found');
          return [];
        }

        final results = data['meals'] as List;
        print('Found ${results.length} recipes');

        return results.map((json) => Recipe.fromMealDBJson(json)).toList();
      } else {
        print('Error: ${response.statusCode}');
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw Exception('Failed to load recipes: $e');
    }
  }

  // Recherche par catégorie
  static Future<List<Recipe>> searchByCategory(String category) async {
    try {
      // Mapping des catégories vers TheMealDB
      String mealCategory = _mapCategoryToMealDB(category);

      final uri = Uri.parse('$baseUrl/filter.php?c=$mealCategory');
      print('Fetching category: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['meals'] == null) {
          return [];
        }

        final results = data['meals'] as List;

        // Les résultats de filter.php sont limités, on récupère les détails
        List<Recipe> recipes = [];
        for (var meal in results.take(10)) {
          try {
            final detailedRecipe = await getRecipeDetails(meal['idMeal']);
            recipes.add(detailedRecipe);
          } catch (e) {
            print('Error fetching meal details: $e');
          }
        }

        return recipes;
      } else {
        throw Exception('Failed to load category');
      }
    } catch (e) {
      print('Error fetching category: $e');
      throw Exception('Failed to load category: $e');
    }
  }

  // Recherche par zone géographique
  static Future<List<Recipe>> searchByArea(String area) async {
    try {
      final uri = Uri.parse('$baseUrl/filter.php?a=$area');
      print('Fetching area: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['meals'] == null) {
          return [];
        }

        final results = data['meals'] as List;

        List<Recipe> recipes = [];
        for (var meal in results.take(10)) {
          try {
            final detailedRecipe = await getRecipeDetails(meal['idMeal']);
            recipes.add(detailedRecipe);
          } catch (e) {
            print('Error fetching meal details: $e');
          }
        }

        return recipes;
      } else {
        throw Exception('Failed to load area recipes');
      }
    } catch (e) {
      print('Error fetching area recipes: $e');
      throw Exception('Failed to load area recipes: $e');
    }
  }

  // Obtenir des recettes aléatoires
  static Future<List<Recipe>> getRandomRecipes({int number = 10}) async {
    try {
      List<Recipe> recipes = [];

      for (int i = 0; i < number; i++) {
        final uri = Uri.parse('$baseUrl/random.php');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
            final mealJson = data['meals'][0];
            recipes.add(Recipe.fromMealDBJson(mealJson));
          }
        }
      }

      print('Found ${recipes.length} random recipes');
      return recipes;
    } catch (e) {
      print('Error fetching random recipes: $e');
      throw Exception('Failed to load random recipes: $e');
    }
  }

  // Obtenir les détails d'une recette
  static Future<Recipe> getRecipeDetails(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/lookup.php?i=$id');
      print('Fetching details for recipe $id');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['meals'] == null || (data['meals'] as List).isEmpty) {
          throw Exception('Recipe not found');
        }

        return Recipe.fromMealDBJson(data['meals'][0]);
      } else {
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
      throw Exception('Failed to load recipe details: $e');
    }
  }

  // Obtenir toutes les catégories disponibles
  static Future<List<String>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/categories.php');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = data['categories'] as List;
        return categories.map((c) => c['strCategory'] as String).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Mapping des catégories vers TheMealDB
  static String _mapCategoryToMealDB(String category) {
    switch (category.toLowerCase()) {
      case 'lunch':
      case 'dinner':
        return 'Beef';
      case 'breakfast':
        return 'Breakfast';
      case 'dessert':
        return 'Dessert';
      case 'vegetarian':
        return 'Vegetarian';
      case 'seafood':
        return 'Seafood';
      case 'pasta':
        return 'Pasta';
      case 'chicken':
        return 'Chicken';
      default:
        return 'Beef';
    }
  }
}