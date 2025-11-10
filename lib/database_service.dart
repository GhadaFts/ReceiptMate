import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
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
      'addedAt': DateTime.now(),
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
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // ==================== FAVORITES ====================
  static Future<void> addToFavorites(String userId, String receiptId) async {
    final db = FirebaseFirestore.instance;
    await db.collection('favorites').add({
      'userId': userId,
      'receipt_id': receiptId,
      'savedAt': DateTime.now(),
    });
    print('✅ Recette $receiptId ajoutée aux favoris');
  }

  static Future<void> removeFromFavorites(String favoriteId) async {
    final db = FirebaseFirestore.instance;
    await db.collection('favorites').doc(favoriteId).delete();
  }

  static Stream<QuerySnapshot> getUserFavorites(String userId) {
    final db = FirebaseFirestore.instance;
    return db.collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // Vérifier si une recette est en favoris
  static Future<bool> isRecipeFavorite(String userId, String receiptId) async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('receipt_id', isEqualTo: receiptId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}