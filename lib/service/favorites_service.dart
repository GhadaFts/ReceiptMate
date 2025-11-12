import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../database_service.dart';

class FavoritesService {
  static final DatabaseService _databaseService = DatabaseService();

  static Future<List<Recipe>> getFavorites() async {
    return await _databaseService.getFavorites();
  }

  static Future<bool> addFavorite(Recipe recipe) async {
    return await _databaseService.addFavorite(recipe);
  }

  static Future<bool> removeFavorite(String recipeId) async {
    return await _databaseService.removeFavorite(recipeId);
  }

  static Future<bool> isFavorite(String recipeId) async {
    return await _databaseService.isRecipeFavorite(recipeId);
  }

  static Future<bool> toggleFavorite(Recipe recipe) async {
    return await _databaseService.toggleFavorite(recipe);
  }

  static Future<void> clearAllFavorites() async {
    await _databaseService.clearAllFavorites();
  }

  static Future<int> getFavoritesCount() async {
    return await _databaseService.getFavoritesCount();
  }

  // Stream pour les mises à jour en temps réel
  static Stream<List<Recipe>> watchFavorites() {
    return _databaseService.watchFavorites();
  }

  // Vérifier si l'utilisateur est connecté
  static bool get isUserLoggedIn {
    return FirebaseAuth.instance.currentUser != null;
  }
}