import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../service/favorites_service.dart';
import '../pages/recipe_detail_page.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RECIPE CARD - CARTE DE RECETTE VERTICALE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Widget réutilisable pour afficher une recette sous forme de carte
///
/// Caractéristiques:
/// - Photo de la recette en haut (65% de la hauteur)
/// - Bouton favori en overlay (top-right)
/// - Nom de la recette (max 2 lignes)
/// - Description courte (1 ligne)
/// - Badge calories en vert
/// - Navigation vers la page détails au tap
/// - Gestion asynchrone des favoris avec Firebase
///
/// Dimensions par défaut: 180x240 pixels
/// ═══════════════════════════════════════════════════════════════════════════

class RecipeCard extends StatefulWidget {
  /// Objet recette à afficher
  final Recipe recipe;

  /// Largeur de la carte (par défaut: 180px)
  final double width;

  /// Hauteur de la carte (par défaut: 240px)
  final double height;

  /// Liste des allergies de l'utilisateur (pour warnings)
  final List<String>? userAllergies;

  /// Afficher ou cacher le bouton favori (par défaut: true)
  final bool showFavoriteButton;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.width = 180,
    this.height = 240,
    this.userAllergies,
    this.showFavoriteButton = true,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  // ═══════════════════════════════════════════════════════════════════════════
  // VARIABLES D'ÉTAT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indicateur si la recette est dans les favoris
  bool _isFavorite = false;

  /// Indicateur de chargement pour l'action favoris
  bool _isLoadingFavorite = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // Vérifier si la recette est déjà en favoris
    _checkIfFavorite();
  }

  /// Vérifie dans Firestore si cette recette est en favoris
  Future<void> _checkIfFavorite() async {
    // Si pas d'ID, impossible de vérifier
    if (widget.recipe.id == null) return;

    try {
      final isFav = await FavoritesService.isFavorite(widget.recipe.id!);

      // Mettre à jour l'état seulement si le widget existe encore
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('❌ Erreur vérification favoris: $e');
    }
  }

  /// Ajoute ou retire la recette des favoris
  Future<void> _toggleFavorite() async {
    if (widget.recipe.id == null) return;

    // ─────────────────────────────────────────────────────────────────────
    // Vérifier que l'utilisateur est connecté
    // ─────────────────────────────────────────────────────────────────────
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

    // Afficher le spinner de chargement
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      // ─────────────────────────────────────────────────────────────────────
      // Appel au service pour toggle le favori dans Firestore
      // ─────────────────────────────────────────────────────────────────────
      final success = await FavoritesService.toggleFavorite(widget.recipe);

      if (mounted) {
        setState(() {
          _isFavorite = success;
          _isLoadingFavorite = false;
        });
      }

      // ─────────────────────────────────────────────────────────────────────
      // Afficher une notification de succès
      // ─────────────────────────────────────────────────────────────────────
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris'),
            backgroundColor: _isFavorite ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTION DE L'INTERFACE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ─────────────────────────────────────────────────────────────────────
      // Navigation vers la page détails au tap
      // ─────────────────────────────────────────────────────────────────────
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(
              recipe: widget.recipe,
              userAllergies: widget.userAllergies,
            ),
          ),
        );
      },
      child: Container(
        width: widget.width,
        margin: const EdgeInsets.only(right: 16), // Espacement entre cartes
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═════════════════════════════════════════════════════════════════
            // IMAGE DE LA RECETTE + BOUTON FAVORI
            // ═════════════════════════════════════════════════════════════════
            Stack(
              children: [
                // ─────────────────────────────────────────────────────────────
                // Container avec image de fond
                // ─────────────────────────────────────────────────────────────
                Container(
                  height: widget.height * 0.65, // 65% de la hauteur totale
                  width: widget.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(widget.recipe.imageUrl),
                      fit: BoxFit.cover, // Image couvre tout l'espace
                    ),
                    // Ombre portée subtile
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2), // Ombre vers le bas
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────────────────────────────────────────
                // Bouton favori (top-right)
                // ─────────────────────────────────────────────────────────────
                if (widget.showFavoriteButton)
                  Positioned(
                    top: 8,
                    right: 8,
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
                        // ─────────────────────────────────────────────────
                        // Spinner de chargement
                        // ─────────────────────────────────────────────────
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        // ─────────────────────────────────────────────────
                        // Icône cœur (plein si favori, vide sinon)
                        // ─────────────────────────────────────────────────
                            : Icon(
                          _isFavorite
                              ? Icons.favorite      // Cœur plein
                              : Icons.favorite_border, // Cœur vide
                          color: _isFavorite
                              ? Colors.red
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ═════════════════════════════════════════════════════════════════
            // NOM DE LA RECETTE
            // ═════════════════════════════════════════════════════════════════
            Text(
              widget.recipe.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2, // Maximum 2 lignes
              overflow: TextOverflow.ellipsis, // "..." si trop long
            ),
            const SizedBox(height: 2),

            // ═════════════════════════════════════════════════════════════════
            // DESCRIPTION COURTE
            // ═════════════════════════════════════════════════════════════════
            Text(
              widget.recipe.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1, // Une seule ligne
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // ═════════════════════════════════════════════════════════════════
            // BADGE CALORIES
            // ═════════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.recipe.calories} Kcal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


///  recettes populaires

class RecipeCardHorizontal extends StatefulWidget {
  final Recipe recipe;
  final List<String>? userAllergies;
  final bool showFavoriteButton;

  const RecipeCardHorizontal({
    super.key,
    required this.recipe,
    this.userAllergies,
    this.showFavoriteButton = true,
  });

  @override
  State<RecipeCardHorizontal> createState() => _RecipeCardHorizontalState();
}

class _RecipeCardHorizontalState extends State<RecipeCardHorizontal> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (widget.recipe.id == null) return;

    try {
      final isFav = await FavoritesService.isFavorite(widget.recipe.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('❌ Erreur vérification favoris: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.recipe.id == null) return;

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
      final success = await FavoritesService.toggleFavorite(widget.recipe);

      if (mounted) {
        setState(() {
          _isFavorite = success;
          _isLoadingFavorite = false;
        });
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(
              recipe: widget.recipe,
              userAllergies: widget.userAllergies,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // ═════════════════════════════════════════════════════════════════
            // IMAGE CARRÉE (70x70)
            // ═════════════════════════════════════════════════════════════════
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(widget.recipe.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ═════════════════════════════════════════════════════════════════
            // INFORMATIONS (Nom, description, calories)
            // ═════════════════════════════════════════════════════════════════
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom de la recette
                  Text(
                    widget.recipe.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Description
                  Text(
                    widget.recipe.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Badge calories
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.recipe.calories} Kcal',
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

            // ═════════════════════════════════════════════════════════════════
            // BOUTON FAVORI (droite)
            // ═════════════════════════════════════════════════════════════════
            if (widget.showFavoriteButton)
              GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: _isLoadingFavorite
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _isFavorite
                        ? Colors.red
                        : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}