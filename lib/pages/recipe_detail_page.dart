import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../models/recipe.dart';
import '../models/allergy.dart';
import '../service/recipe_service.dart';
import '../service/favorites_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final List<String>? userAllergies;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    this.userAllergies,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Recipe? detailedRecipe;
  bool isLoading = true;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _loadRecipeDetails();
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
      print('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.recipe.id == null) return;

    if (!FavoritesService.isUserLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour ajouter aux favoris'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final recipe = detailedRecipe ?? widget.recipe;
      final success = await FavoritesService.toggleFavorite(recipe);

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

  // MÉTHODE CORRIGÉE POUR YOUTUBE
  Future<void> _launchYouTube(String url) async {
    try {
      print('Tentative de lancement YouTube: $url');

      if (url.isEmpty) {
        print(' URL YouTube vide');
        _showNoYouTubeDialog();
        return;
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        print('✅ URL YouTube valide, lancement...');
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ YouTube lancé avec succès');
      } else {
        print('❌ Impossible de lancer l URL YouTube');
        _showNoYouTubeDialog();
      }
    } catch (e) {
      print('❌ Erreur lors du lancement YouTube: $e');
      _showNoYouTubeDialog();
    }
  }

  void _showNoYouTubeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vidéo non disponible'),
        content: const Text('Cette recette ne fournit pas de méthode de préparation sur YouTube.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _getYouTubeUrl(Recipe recipe) {
    final youtubeMap = {
      '52868': 'https://www.youtube.com/watch?v=FS8u1RBdf6I',
      '52771': 'https://www.youtube.com/watch?v=3A0V-7x7dAw',
      '52795': 'https://www.youtube.com/watch?v=0n3fPe4fP_s',
      '52776': 'https://www.youtube.com/watch?v=JxGE0y2fT1A',
      '52834': 'https://www.youtube.com/watch?v=PQHgSfLP-D4',
    };

    // Priorité 1: URL hardcodée
    if (youtubeMap.containsKey(recipe.id)) {
      return youtubeMap[recipe.id];
    }

    // Priorité 2: URL formatée
    final formattedUrl = recipe.formattedYoutubeUrl;
    if (formattedUrl != null && formattedUrl.isNotEmpty && formattedUrl != 'null') {
      return formattedUrl;
    }

    // Priorité 3: URL originale
    if (recipe.youtubeUrl != null && recipe.youtubeUrl!.isNotEmpty && recipe.youtubeUrl != 'null') {
      return recipe.youtubeUrl;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = detailedRecipe ?? widget.recipe;
    final youtubeUrl = _getYouTubeUrl(recipe);

    // Debug
    print('🎬 Recipe: ${recipe.name}');
    print('🎬 YouTube URL: $youtubeUrl');

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                      );
                    },
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
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                  ),
                  if (_isLoadingFavorite)
                    Positioned.fill(
                      child: Container(
                        color: Colors.transparent,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: youtubeUrl != null ? Colors.white : Colors.grey.shade400,
                ),
                onPressed: () {
                  if (youtubeUrl != null) {
                    _launchYouTube(youtubeUrl);
                  } else {
                    _showNoYouTubeDialog();
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  if (widget.userAllergies != null &&
                      widget.userAllergies!.isNotEmpty &&
                      recipe.ingredients != null)
                    _buildAllergyWarning(recipe),
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
                  _buildNutritionDistribution(recipe),
                  const SizedBox(height: 24),
                  _buildMacronutrients(recipe),
                  const SizedBox(height: 24),
                  if (recipe.ingredients != null &&
                      recipe.ingredients!.isNotEmpty)
                    _buildIngredientsSection(recipe.ingredients!),
                  const SizedBox(height: 24),
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

  // ... Gardez toutes vos autres méthodes _build... existantes
  // Elles restent identiques à votre code original
  Widget _buildAllergyWarning(Recipe recipe) {
    final ingredientNames = recipe.ingredients!
        .map((i) => i.name.toLowerCase())
        .toList();

    final foundAllergens = AllergyData.findAllergensInRecipe(
      ingredientNames,
      widget.userAllergies!,
    );

    if (foundAllergens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cette recette ne contient aucun de vos allergènes',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ ATTENTION - Allergènes détectés',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cette recette contient:',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...foundAllergens.map((allergen) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.close, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  allergen,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
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

// ... Gardez vos autres classes (_InfoBadge, _LegendItem, etc.)
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

    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}