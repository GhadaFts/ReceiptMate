import 'package:flutter/material.dart';
import 'dart:async';
import '../models/recipe.dart';
import '../service/favorites_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/custom_drawer.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Recipe> favoriteRecipes = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _setupFavorites();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  void _setupFavorites() {
    if (!FavoritesService.isUserLoggedIn) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connectez-vous pour voir vos favoris';
      });
      return;
    }

    // Essayer d'abord le chargement simple
    _loadFavorites();

    // Ensuite configurer le stream
    try {
      _favoritesSubscription = FavoritesService.watchFavorites().listen(
            (favorites) {
          if (mounted) {
            setState(() {
              favoriteRecipes = favorites;
              isLoading = false;
              errorMessage = null;
            });
          }
        },
        onError: (error) {
          print('Error in favorites stream: $error');
          if (mounted) {
            setState(() {
              errorMessage = 'Chargement en mode simple';
            });
          }
        },
      );
    } catch (e) {
      print('Error setting up stream: $e');
    }
  }

  Future<void> _loadFavorites() async {
    if (!FavoritesService.isUserLoggedIn) {
      setState(() {
        isLoading = false;
        favoriteRecipes = [];
        errorMessage = 'Connectez-vous pour voir vos favoris';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final favorites = await FavoritesService.getFavorites();
      if (mounted) {
        setState(() {
          favoriteRecipes = favorites;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur de chargement des favoris';
        });
      }
    }
  }

  Future<void> _removeFavorite(Recipe recipe) async {
    try {
      await FavoritesService.removeFavorite(recipe.id!);
      // Recharger après suppression
      _loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recipe.name} retiré des favoris'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () async {
                await FavoritesService.addFavorite(recipe);
                _loadFavorites();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les favoris ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tous vos favoris ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FavoritesService.clearAllFavorites();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tous les favoris ont été supprimés'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (favoriteRecipes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.black),
              onPressed: _clearAllFavorites,
              tooltip: 'Supprimer tous les favoris',
            ),
        ],
      ),
      drawer: const CustomDrawer(currentRoute: '/favoris'),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : favoriteRecipes.isEmpty
            ? _buildEmptyState()
            : _buildFavoritesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Aucun favori',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Commencez à ajouter des recettes à vos favoris en appuyant sur le cœur ❤️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explorer les recettes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Header avec compteur
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.pink.shade400],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
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
                  Icons.favorite,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes Favoris',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${favoriteRecipes.length} recette${favoriteRecipes.length > 1 ? 's' : ''} sauvegardée${favoriteRecipes.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Message d'erreur
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Liste des favoris
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoriteRecipes.length,
            itemBuilder: (context, index) {
              final recipe = favoriteRecipes[index];
              return Stack(
                children: [
                  RecipeCard(
                    recipe: recipe,
                    width: double.infinity,
                    showFavoriteButton: false, // IMPORTANT: Désactive le cœur interne
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeFavorite(recipe),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}