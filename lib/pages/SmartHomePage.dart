import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../service/recipe_service.dart';
import '../service/gemini_service.dart';
import '../database_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/allergy_filter.dart';

class SmartHomePage extends StatefulWidget {
  const SmartHomePage({super.key});

  @override
  State<SmartHomePage> createState() => _SmartHomePageState();
}

class _SmartHomePageState extends State<SmartHomePage> {
  String selectedCategory = 'Lunch';
  List<RecipeRecommendation> aiRecommendations = [];
  List<Recipe> popularRecipes = [];
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> pantryItems = [];

  bool isLoadingAI = false;
  bool isLoadingPopular = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load user profile
      final userDoc = await DatabaseService.getUser(user.uid);
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      }

      // Load pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry')
          .where('userId', isEqualTo: user.uid)
          .get();

      pantryItems = pantrySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'ingredient': data['ingredient'],
          'quantity': data['quantity'],
        };
      }).toList();

      // Load recipes and get AI recommendations
      await _loadAIRecommendations();
      await _loadPopularRecipes();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        errorMessage = 'Error loading data';
      });
    }
  }

  Future<void> _loadAIRecommendations() async {
    if (userData == null) return;

    setState(() {
      isLoadingAI = true;
      errorMessage = null;
    });

    try {
      // Fetch recipes for the selected category
      final recipes = await RecipeService.searchByCategory(selectedCategory);

      // Get AI recommendations
      final recommendations = await GeminiService.getRecipeRecommendations(
        userData: userData!,
        pantryItems: pantryItems,
        recipes: recipes,
      );

      setState(() {
        aiRecommendations = recommendations;
        isLoadingAI = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting AI recommendations';
        isLoadingAI = false;
      });
      print('Error loading AI recommendations: $e');
    }
  }

  Future<void> _loadPopularRecipes() async {
    setState(() {
      isLoadingPopular = true;
    });

    try {
      final recipes = await RecipeService.getRandomRecipes(number: 5);
      setState(() {
        popularRecipes = recipes;
        isLoadingPopular = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPopular = false;
      });
      print('Error loading popular recipes: $e');
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
    });
    _loadAIRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final userAllergies = (userData?['allergies'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            const Spacer(),
            if (userAllergies.isNotEmpty)
              AllergyBadge(
                count: userAllergies.length,
                onTap: () {},
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _loadUserData();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Recommendations Badge
                if (userData != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✨ AI-Powered Recommendations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Personalized for your goals & pantry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title
                const Text(
                  'Healthy Salads',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Healthy and nutritious food recipes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Categories
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryChip(
                        icon: Icons.restaurant,
                        label: 'Lunch',
                        isSelected: selectedCategory == 'Lunch',
                        onTap: () => _onCategoryChanged('Lunch'),
                      ),
                      const SizedBox(width: 12),
                      CategoryChip(
                        icon: Icons.breakfast_dining,
                        label: 'Breakfast',
                        isSelected: selectedCategory == 'Breakfast',
                        onTap: () => _onCategoryChanged('Breakfast'),
                      ),
                      const SizedBox(width: 12),
                      CategoryChip(
                        icon: Icons.cake,
                        label: 'Dessert',
                        isSelected: selectedCategory == 'Dessert',
                        onTap: () => _onCategoryChanged('Dessert'),
                      ),
                      const SizedBox(width: 12),
                      CategoryChip(
                        icon: Icons.eco,
                        label: 'Vegetarian',
                        isSelected: selectedCategory == 'Vegetarian',
                        onTap: () => _onCategoryChanged('Vegetarian'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // AI Recommendations Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (pantryItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.kitchen, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${pantryItems.length} items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error message
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // AI Recommendations List
                SizedBox(
                  height: 320,
                  child: isLoadingAI
                      ? const Center(child: CircularProgressIndicator())
                      : aiRecommendations.isEmpty
                      ? _buildEmptyAIState()
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: aiRecommendations.length,
                    itemBuilder: (context, index) {
                      return AIRecipeCard(
                        recommendation: aiRecommendations[index],
                        userAllergies: userAllergies,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Popular recipes section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular recipes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadPopularRecipes,
                      child: Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Popular recipes list
                if (isLoadingPopular)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...popularRecipes.map(
                        (recipe) => RecipeCardHorizontal(
                      recipe: recipe,
                      userAllergies: userAllergies,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAIState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            pantryItems.isEmpty
                ? 'Add items to your pantry\nfor better recommendations!'
                : 'Loading AI recommendations...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          if (pantryItems.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/pantry');
              },
              icon: const Icon(Icons.kitchen),
              label: const Text('Go to Pantry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search recipes'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Type your search...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (searchController.text.isNotEmpty) {
                // Handle search
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

// AI Recipe Card Widget
class AIRecipeCard extends StatelessWidget {
  final RecipeRecommendation recommendation;
  final List<String>? userAllergies;

  const AIRecipeCard({
    super.key,
    required this.recommendation,
    this.userAllergies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with score badge
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(recommendation.recipe.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: recommendation.scoreColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${recommendation.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe name
                  Text(
                    recommendation.recipe.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Score label
                  Text(
                    recommendation.scoreLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: recommendation.scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Recommendation text
                  Text(
                    recommendation.recommendation,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Calories
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${recommendation.recipe.calories} Kcal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}