import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/allergy.dart';
import '../service/recipe_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecipes();
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
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de chargement des recettes';
        isLoadingCategory = false;
      });
      print('Error loading category recipes: $e');
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
    _loadCategoryRecipes();
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
            // Badge allergies - VISIBLE ICI
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
              _loadRecipes();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadRecipes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            '${filteredCategoryRecipes.length} recettes sans ${selectedAllergies.map((id) => AllergyData.getAllergies().firstWhere((a) => a.id == id).displayName).join(', ')}',
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
                  height: 280,
                  child: isLoadingCategory
                      ? const Center(child: CircularProgressIndicator())
                      : filteredCategoryRecipes.isEmpty
                      ? Center(
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
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredCategoryRecipes.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(
                        recipe: filteredCategoryRecipes[index],
                        userAllergies: selectedAllergies,
                      );
                    },
                  ),
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