import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== USERS ====================
  static Future<void> createUser(String userId, String email, {String healthTarget = ''}) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(userId).set({
      'email': email,
      'allergies': [],
      'healthTarget': healthTarget,
      'preferences': [],
      'createdAt': DateTime.now(),
      'onboardingCompleted': false,
    });
    print('✅ Utilisateur $email créé');
  }

  static Future<void> updateUserAllergies(String userId, List<String> allergies) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(userId).update({
      'allergies': allergies,
    });
  }

  static Future<DocumentSnapshot> getUser(String userId) async {
    final db = FirebaseFirestore.instance;
    return await db.collection('users').doc(userId).get();
  }

  static Stream<DocumentSnapshot> getUserStream(String userId) {
    final db = FirebaseFirestore.instance;
    return db.collection('users').doc(userId).snapshots();
  }

  // ==================== PANTRY ====================
  static Future<void> addToPantry(String userId, String ingredient, String quantity) async {
    final db = FirebaseFirestore.instance;
    await db.collection('pantry').add({
      'userId': userId,
      'ingredient': ingredient,
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Ingredient $ingredient ajouté au pantry');
  }

  static Future<void> removeFromPantry(String itemId) async {
    final db = FirebaseFirestore.instance;
    await db.collection('pantry').doc(itemId).delete();
  }

  static Stream<QuerySnapshot> getUserPantry(String userId) {
    final db = FirebaseFirestore.instance;
    return db.collection('pantry')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // ==================== FAVORITES ====================

  // Obtenir l'ID de l'utilisateur courant
  String? get _currentUserId => _auth.currentUser?.uid;

  // Vérifier si l'utilisateur est connecté
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Ajouter une recette aux favoris
  Future<bool> addFavorite(Recipe recipe) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier si déjà en favoris
      final isAlreadyFavorite = await isRecipeFavorite(recipe.id!);
      if (isAlreadyFavorite) {
        return false;
      }

      // Créer un document favori
      await _firestore.collection('favorites').add({
        'userId': _currentUserId,
        'recipeId': recipe.id,
        'recipeName': recipe.name,
        'recipeImage': recipe.imageUrl,
        'recipeCategory': recipe.category,
        'calories': recipe.calories,
        'ingredients': recipe.ingredients?.map((ing) => ing.toJson()).toList(),
        'instructions': recipe.instructions,
        'savedAt': FieldValue.serverTimestamp(),
        'recipeData': recipe.toJson(),
      });

      print('✅ Recette ${recipe.name} ajoutée aux favoris');
      return true;
    } catch (e) {
      print('❌ Erreur ajout favori: $e');
      throw e;
    }
  }

  // Retirer une recette des favoris
  Future<bool> removeFavorite(String recipeId) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('Utilisateur non connecté');
      }

      // Trouver le document favori
      final querySnapshot = await _firestore.collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .where('recipeId', isEqualTo: recipeId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      // Supprimer tous les documents correspondants
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Recette $recipeId retirée des favoris');
      return true;
    } catch (e) {
      print('❌ Erreur suppression favori: $e');
      throw e;
    }
  }

  // Vérifier si une recette est en favoris
  Future<bool> isRecipeFavorite(String recipeId) async {
    try {
      if (!isUserLoggedIn) return false;

      final querySnapshot = await _firestore.collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .where('recipeId', isEqualTo: recipeId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification favori: $e');
      return false;
    }
  }

  // Obtenir toutes les recettes favorites
  Future<List<Recipe>> getFavorites() async {
    try {
      if (!isUserLoggedIn) return [];

      final querySnapshot = await _firestore.collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('savedAt', descending: true)
          .get();

      final favorites = <Recipe>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        try {
          // Reconstruire la recette depuis recipeData
          if (data.containsKey('recipeData')) {
            final recipeData = data['recipeData'] as Map<String, dynamic>;
            final recipe = Recipe.fromJson(recipeData);
            favorites.add(recipe);
          }
        } catch (e) {
          print('❌ Erreur parsing recette favori: $e');
        }
      }

      return favorites;
    } catch (e) {
      print('❌ Erreur récupération favoris: $e');
      return [];
    }
  }

  // Stream des favoris (pour mise à jour en temps réel)
  Stream<List<Recipe>> watchFavorites() {
    if (!isUserLoggedIn) return Stream.value([]);

    return _firestore.collection('favorites')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('recipeData')) {
          final recipeData = data['recipeData'] as Map<String, dynamic>;
          return Recipe.fromJson(recipeData);
        } else {
          // Fallback
          // Fallback
          return Recipe(
            id: data['recipeId'] ?? doc.id,
            name: data['recipeName'] ?? 'Recette sans nom',
            description: data['recipeDescription'] ?? 'Description non disponible', // AJOUTEZ description
            calories: data['calories'] ?? 0,
            imageUrl: data['recipeImage'] ?? '',
            category: data['recipeCategory'] ?? '',
            isFavorite: true,
          );
        }
      }).toList();
    });
  }

  // Basculer le statut favori
  Future<bool> toggleFavorite(Recipe recipe) async {
    final isFav = await isRecipeFavorite(recipe.id!);

    if (isFav) {
      await removeFavorite(recipe.id!);
      return false;
    } else {
      await addFavorite(recipe);
      return true;
    }
  }

  // Supprimer tous les favoris
  Future<void> clearAllFavorites() async {
    try {
      if (!isUserLoggedIn) return;

      final querySnapshot = await _firestore.collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // Supprimer tous les documents en batch
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Tous les favoris supprimés');
    } catch (e) {
      print('❌ Erreur suppression tous favoris: $e');
      throw e;
    }
  }

  // Obtenir le nombre de favoris
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}