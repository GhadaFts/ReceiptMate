import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../pages/recipe_detail_page.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final double width;
  final double height;
  final List<String>? userAllergies;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.width = 180,
    this.height = 280,
    this.userAllergies,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: widget.recipe),
          ),
        );
      },
      child: Container(
        width: widget.width,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container avec bouton favori
            Stack(
              children: [
                Container(
                  height: widget.height * 0.7,
                  width: widget.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(widget.recipe.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.recipe.isFavorite = !widget.recipe.isFavorite;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: Icon(
                        widget.recipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.recipe.isFavorite
                            ? Colors.red
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nom de la recette
            Text(
              widget.recipe.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              widget.recipe.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Calories
            Row(
              children: [
                Text(
                  '${widget.recipe.calories} Kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Version verticale pour la section Popular
class RecipeCardHorizontal extends StatefulWidget {
  final Recipe recipe;
  final List<String> userAllergies; // AJOUTER CETTE LIGNE


  const RecipeCardHorizontal({
    super.key,
    required this.recipe,
    this.userAllergies = const [], // AJOUTER CETTE LIGNE avec valeur par défaut

  });

  @override
  State<RecipeCardHorizontal> createState() => _RecipeCardHorizontalState();
}

class _RecipeCardHorizontalState extends State<RecipeCardHorizontal> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: widget.recipe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(widget.recipe.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.recipe.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.recipe.calories} Kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton favori
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.recipe.isFavorite = !widget.recipe.isFavorite;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  widget.recipe.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.recipe.isFavorite
                      ? Colors.red
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}