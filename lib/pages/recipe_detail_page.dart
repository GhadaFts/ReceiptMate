import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/recipe.dart';
import '../models/allergy.dart';
import '../service/recipe_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Recipe? detailedRecipe;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    try {
      final recipe = await RecipeService.getRecipeDetails(widget.recipe.id);
      setState(() {
        detailedRecipe = recipe;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        detailedRecipe = widget.recipe;
        isLoading = false;
      });
      print('Error loading details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = detailedRecipe ?? widget.recipe;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  recipe.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    recipe.isFavorite = !recipe.isFavorite;
                  });
                },
              ),
              if (recipe.youtubeUrl != null)
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                  onPressed: () {
                    // Ouvrir YouTube (vous pouvez utiliser url_launcher)
                    print('Open YouTube: ${recipe.youtubeUrl}');
                  },
                ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Catégorie et origine
                  Row(
                    children: [
                      _InfoBadge(
                        icon: Icons.restaurant_menu,
                        label: recipe.category,
                        color: Colors.green,
                      ),
                      if (recipe.area != null) ...[
                        const SizedBox(width: 8),
                        _InfoBadge(
                          icon: Icons.public,
                          label: recipe.area!,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Calories principale
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${recipe.calories}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'KCAL',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distribution nutritionnelle
                  _buildNutritionDistribution(recipe),
                  const SizedBox(height: 24),

                  // Macronutriments
                  _buildMacronutrients(recipe),
                  const SizedBox(height: 24),

                  // Ingrédients
                  if (recipe.ingredients != null &&
                      recipe.ingredients!.isNotEmpty)
                    _buildIngredientsSection(recipe.ingredients!),

                  const SizedBox(height: 24),

                  // Instructions
                  if (recipe.instructions != null)
                    _buildInstructionsSection(recipe.instructions!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionDistribution(Recipe recipe) {
    final distribution = recipe.nutritionDistribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribution Nutritionnelle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Graphique circulaire
        Center(
          child: SizedBox(
            height: 200,
            width: 200,
            child: CustomPaint(
              painter: NutritionPieChart(
                proteinPercent: distribution['protein']!,
                carbsPercent: distribution['carbs']!,
                fatPercent: distribution['fat']!,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Légende
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendItem(
              color: Colors.red.shade400,
              label: 'Protéines',
              percent: distribution['protein']!,
            ),
            _LegendItem(
              color: Colors.blue.shade400,
              label: 'Glucides',
              percent: distribution['carbs']!,
            ),
            _LegendItem(
              color: Colors.orange.shade400,
              label: 'Lipides',
              percent: distribution['fat']!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacronutrients(Recipe recipe) {
    final macros = recipe.estimatedMacros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Macronutriments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroItem(
                label: 'Protéines',
                value: '${macros['protein']!.toStringAsFixed(0)}g',
                color: Colors.red.shade400,
                icon: Icons.fitness_center,
              ),
              _MacroItem(
                label: 'Glucides',
                value: '${macros['carbs']!.toStringAsFixed(0)}g',
                color: Colors.blue.shade400,
                icon: Icons.grain,
              ),
              _MacroItem(
                label: 'Lipides',
                value: '${macros['fat']!.toStringAsFixed(0)}g',
                color: Colors.orange.shade400,
                icon: Icons.water_drop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(List<Ingredient> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_basket, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Ingrédients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${ingredients.length} items',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ingredients.map((ingredient) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ingredient.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.restaurant,
                          color: Colors.grey.shade400,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ingredient.measure.isNotEmpty)
                        Text(
                          ingredient.measure,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildInstructionsSection(String instructions) {
    // Diviser les instructions en étapes
    final steps = instructions
        .split(RegExp(r'\r\n|\r|\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Préparation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      step.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// Widget pour les badges d'info
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour les items de légende
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget pour les macronutriments
class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// Custom Painter pour le graphique circulaire
class NutritionPieChart extends CustomPainter {
  final double proteinPercent;
  final double carbsPercent;
  final double fatPercent;

  NutritionPieChart({
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    // Protéines (rouge)
    final proteinSweep = (proteinPercent / 100) * 2 * math.pi;
    final proteinPaint = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      proteinSweep,
      true,
      proteinPaint,
    );
    startAngle += proteinSweep;

    // Glucides (bleu)
    final carbsSweep = (carbsPercent / 100) * 2 * math.pi;
    final carbsPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      carbsSweep,
      true,
      carbsPaint,
    );
    startAngle += carbsSweep;

    // Lipides (orange)
    final fatSweep = (fatPercent / 100) * 2 * math.pi;
    final fatPaint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fatSweep,
      true,
      fatPaint,
    );

    // Cercle blanc au centre
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}