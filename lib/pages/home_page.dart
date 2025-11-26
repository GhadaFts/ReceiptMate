import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_flutter/pages/recipe_detail_page.dart';
import '../models/recipe.dart';
import '../models/allergy.dart';
import '../service/favorites_service.dart';
import '../service/recipe_service.dart';
import '../service/gemini_service.dart';
import '../database_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/allergy_filter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'Lunch';
  List<Recipe> categoryRecipes = [];
  List<Recipe> popularRecipes = [];
  List<String> selectedAllergies = [];
  bool isLoadingCategory = false;
  bool isLoadingPopular = false;
  String? errorMessage;

  // AI features
  bool isAIEnabled = false;
  List<RecipeRecommendation> aiRecommendations = [];
  bool isLoadingAI = false;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> pantryItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecipes();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load user profile
      final userDoc = await DatabaseService.getUser(user.uid);
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
        });
      }

      // Load pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        pantryItems = pantrySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'ingredient': data['ingredient'],
            'quantity': data['quantity'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Filtrer les recettes selon les allergies
  List<Recipe> get filteredCategoryRecipes {
    if (selectedAllergies.isEmpty) return categoryRecipes;

    return categoryRecipes.where((recipe) {
      if (recipe.ingredients == null) return true;

      final ingredientNames = recipe.ingredients!
          .map((i) => i.name.toLowerCase())
          .toList();

      return !AllergyData.recipeContainsAllergen(
        ingredientNames,
        selectedAllergies,
      );
    }).toList();
  }

  List<Recipe> get filteredPopularRecipes {
    if (selectedAllergies.isEmpty) return popularRecipes;

    return popularRecipes.where((recipe) {
      if (recipe.ingredients == null) return true;

      final ingredientNames = recipe.ingredients!
          .map((i) => i.name.toLowerCase())
          .toList();

      return !AllergyData.recipeContainsAllergen(
        ingredientNames,
        selectedAllergies,
      );
    }).toList();
  }

  // Get AI-filtered recommendations
  List<RecipeRecommendation> get filteredAIRecommendations {
    if (selectedAllergies.isEmpty) return aiRecommendations;

    return aiRecommendations.where((rec) {
      if (rec.recipe.ingredients == null) return true;

      final ingredientNames = rec.recipe.ingredients!
          .map((i) => i.name.toLowerCase())
          .toList();

      return !AllergyData.recipeContainsAllergen(
        ingredientNames,
        selectedAllergies,
      );
    }).toList();
  }

  Future<void> _loadRecipes() async {
    await Future.wait([
      _loadCategoryRecipes(),
      _loadPopularRecipes(),
    ]);
  }

  Future<void> _loadCategoryRecipes() async {
    setState(() {
      isLoadingCategory = true;
      errorMessage = null;
    });

    try {
      final recipes = await RecipeService.searchByCategory(selectedCategory);
      setState(() {
        categoryRecipes = recipes;
        isLoadingCategory = false;
      });

      // If AI is enabled, load AI recommendations
      if (isAIEnabled && userData != null) {
        _loadAIRecommendations();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de chargement des recettes';
        isLoadingCategory = false;
      });
      print('Error loading category recipes: $e');
    }
  }

  Future<void> _loadAIRecommendations() async {
    if (userData == null || categoryRecipes.isEmpty) return;

    setState(() {
      isLoadingAI = true;
      errorMessage = null;
    });

    try {
      final recommendations = await GeminiService.getRecipeRecommendations(
        userData: userData!,
        pantryItems: pantryItems,
        recipes: categoryRecipes,
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
      aiRecommendations = []; // Clear AI recommendations
    });
    _loadCategoryRecipes();
  }

  void _toggleAI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use AI features')),
      );
      return;
    }

    setState(() {
      isAIEnabled = !isAIEnabled;
    });

    if (isAIEnabled) {
      // Load user data if not loaded
      if (userData == null) {
        await _loadUserData();
      }
      // Load AI recommendations
      if (categoryRecipes.isNotEmpty) {
        await _loadAIRecommendations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Badge allergies
            AllergyBadge(
              count: selectedAllergies.length,
              onTap: () {
                _showAllergyFilter();
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _loadUserData();
              _loadRecipes();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadRecipes();
          if (isAIEnabled) {
            await _loadAIRecommendations();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Toggle Button
                GestureDetector(
                  onTap: _toggleAI,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: isAIEnabled
                          ? LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade400],
                      )
                          : null,
                      color: isAIEnabled ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: isAIEnabled ? null : Border.all(color: Colors.grey.shade300),
                      boxShadow: isAIEnabled
                          ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAIEnabled
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: isAIEnabled ? Colors.white : Colors.grey.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAIEnabled
                                    ? '✨ AI-Powered Recommendations'
                                    : '🤖 Enable AI Recommendations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isAIEnabled ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAIEnabled
                                    ? 'Personalized for your goals & pantry'
                                    : 'Get smart suggestions based on your profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAIEnabled
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isAIEnabled ? Icons.toggle_on : Icons.toggle_off,
                          color: isAIEnabled ? Colors.white : Colors.grey.shade400,
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                ),

                // Titre
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

                // Catégories
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
                      const SizedBox(width: 12),
                      CategoryChip(
                        icon: Icons.set_meal,
                        label: 'Seafood',
                        isSelected: selectedCategory == 'Seafood',
                        onTap: () => _onCategoryChanged('Seafood'),
                      ),
                      const SizedBox(width: 12),
                      CategoryChip(
                        icon: Icons.ramen_dining,
                        label: 'Pasta',
                        isSelected: selectedCategory == 'Pasta',
                        onTap: () => _onCategoryChanged('Pasta'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Pantry info when AI is enabled
                if (isAIEnabled && pantryItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.kitchen, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Using ${pantryItems.length} items from your pantry',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Afficher le nombre de recettes filtrées
                if (selectedAllergies.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${isAIEnabled ? filteredAIRecommendations.length : filteredCategoryRecipes.length} recettes sans ${selectedAllergies.map((id) => AllergyData.getAllergies().firstWhere((a) => a.id == id).displayName).join(', ')}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.orange.shade700, size: 20),
                          onPressed: () {
                            setState(() {
                              selectedAllergies.clear();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Message d'erreur
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

                // Liste horizontale des recettes
                SizedBox(
                  height: isAIEnabled ? 320 : 280,
                  child: (isLoadingCategory || (isAIEnabled && isLoadingAI))
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRecipesList(),
                ),
                const SizedBox(height: 32),

                // Section Popular recipes
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
                      onPressed: () {
                        _loadPopularRecipes();
                      },
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

                // Liste des recettes populaires
                if (isLoadingPopular)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredPopularRecipes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        selectedAllergies.isNotEmpty
                            ? 'Aucune recette populaire compatible'
                            : 'Aucune recette populaire',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredPopularRecipes.map(
                        (recipe) => RecipeCardHorizontal(
                      recipe: recipe,
                      userAllergies: selectedAllergies,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipesList() {
    if (isAIEnabled) {
      // Show AI recommendations
      if (filteredAIRecommendations.isEmpty) {
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
                selectedAllergies.isNotEmpty
                    ? 'No AI recommendations\nmatching your filters'
                    : pantryItems.isEmpty
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

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredAIRecommendations.length,
        itemBuilder: (context, index) {
          return AIRecipeCard(
            recommendation: filteredAIRecommendations[index],
            userAllergies: selectedAllergies,
          );
        },
      );
    } else {
      // Show regular recipes
      if (filteredCategoryRecipes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selectedAllergies.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : Icons.restaurant_menu,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                selectedAllergies.isNotEmpty
                    ? 'Aucune recette compatible\navec vos filtres'
                    : 'Aucune recette trouvée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredCategoryRecipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(
            recipe: filteredCategoryRecipes[index],
            userAllergies: selectedAllergies,
          );
        },
      );
    }
  }

  void _showAllergyFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => AllergyFilterSheet(
          selectedAllergies: selectedAllergies,
          onAllergiesChanged: (allergies) {
            setState(() {
              selectedAllergies = allergies;
            });
          },
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher des recettes'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Tapez votre recherche...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (searchController.text.isNotEmpty) {
                setState(() {
                  isLoadingCategory = true;
                  isAIEnabled = false; // Disable AI for search
                });
                try {
                  final recipes = await RecipeService.searchRecipes(
                    query: searchController.text,
                    number: 20,
                  );
                  setState(() {
                    categoryRecipes = recipes;
                    isLoadingCategory = false;
                  });
                } catch (e) {
                  setState(() {
                    errorMessage = 'Erreur de recherche';
                    isLoadingCategory = false;
                  });
                }
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}

// AI Recipe Card Widget (same as SmartHomePage)
class AIRecipeCard extends StatefulWidget {
  final RecipeRecommendation recommendation;
  final List<String>? userAllergies;

  const AIRecipeCard({
    super.key,
    required this.recommendation,
    this.userAllergies,
  });

  @override
  State<AIRecipeCard> createState() => _AIRecipeCardState();
}

class _AIRecipeCardState extends State<AIRecipeCard> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (widget.recommendation.recipe.id == null) return;

    try {
      final isFav = await FavoritesService.isFavorite(widget.recommendation.recipe.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.recommendation.recipe.id == null) return;

    if (!FavoritesService.isUserLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connectez-vous pour ajouter aux favoris'),
          action: SnackBarAction(
            label: 'Se connecter',
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final success = await FavoritesService.toggleFavorite(widget.recommendation.recipe);

      if (mounted) {
        setState(() {
          _isFavorite = success;
          _isLoadingFavorite = false;
        });
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Ajouté aux favoris !'
                : 'Retiré des favoris'),
            backgroundColor: _isFavorite ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to recipe detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(
              recipe: widget.recommendation.recipe,
              userAllergies: widget.userAllergies,
            ),
          ),
        );
      },
      child: Container(
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
            // Image with score badge and favorite button
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(widget.recommendation.recipe.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // AI Score badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.recommendation.scoreColor,
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
                          '${widget.recommendation.score}',
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
                // Favorite button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isLoadingFavorite
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey.shade600,
                        size: 18,
                      ),
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
                      widget.recommendation.recipe.name,
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
                      widget.recommendation.scoreLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.recommendation.scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Recommendation text
                    Text(
                      widget.recommendation.recommendation,
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
                        '${widget.recommendation.recipe.calories} Kcal',
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
      ),
    );
  }
}