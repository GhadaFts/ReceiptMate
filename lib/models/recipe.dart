class Recipe {
  final String id;
  final String name;
  final String description;
  final int calories;
  final String imageUrl;
  final String category;
  bool isFavorite;
  final String? area;
  final String? tags;
  final String? youtubeUrl;
  final String? sourceUrl;
  final List<Ingredient>? ingredients;
  final String? instructions;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.imageUrl,
    required this.category,
    this.isFavorite = false,
    this.area,
    this.tags,
    this.youtubeUrl,
    this.sourceUrl,
    this.ingredients,
    this.instructions,
  });

  factory Recipe.fromMealDBJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredientName = json['strIngredient$i'];
      final ingredientMeasure = json['strMeasure$i'];

      if (ingredientName != null &&
          ingredientName.toString().trim().isNotEmpty &&
          ingredientName != 'null') {
        ingredients.add(
          Ingredient(
            id: i,
            name: ingredientName.toString().trim(),
            measure: ingredientMeasure?.toString().trim() ?? '',
            imageUrl: 'https://www.themealdb.com/images/ingredients/${ingredientName.toString().trim()}.png',
          ),
        );
      }
    }

    // Calcul approximatif des calories basé sur les ingrédients
    int estimatedCalories = _estimateCalories(ingredients, json['strCategory']);

    // Description basée sur la zone et les tags
    String description = '';
    if (json['strArea'] != null) {
      description = json['strArea'];
    }
    if (json['strTags'] != null && json['strTags'].toString().isNotEmpty) {
      final tags = json['strTags'].toString().split(',').take(2).join(' • ');
      description = description.isEmpty ? tags : '$description • $tags';
    }
    if (description.isEmpty) {
      description = json['strCategory'] ?? 'Delicious recipe';
    }

    return Recipe(
      id: json['idMeal'].toString(),
      name: json['strMeal'] as String,
      description: description,
      calories: estimatedCalories,
      imageUrl: json['strMealThumb'] as String,
      category: json['strCategory'] as String? ?? 'Other',
      area: json['strArea'] as String?,
      tags: json['strTags'] as String?,
      youtubeUrl: json['strYoutube'] as String?,
      sourceUrl: json['strSource'] as String?,
      ingredients: ingredients,
      instructions: json['strInstructions'] as String?,
    );
  }

  String? get formattedYoutubeUrl {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return null;

    String url = youtubeUrl!;

    print('YouTube URL original: $url');

    // Si c'est juste l'ID de la vidéo (sans l'URL complète)
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      return 'https://www.youtube.com/watch?v=$url';
    }

    // Si c'est une URL complète mais mal formatée
    if (url.startsWith('www.')) {
      return 'https://$url';
    }

    // Si l'URL contient 'watch?v=' mais pas 'https://'
    if (url.contains('watch?v=') && !url.startsWith('http')) {
      return 'https://$url';
    }

    return url;
  }

  // Estimation des calories basée sur la catégorie et le nombre d'ingrédients
  static int _estimateCalories(List<Ingredient> ingredients, String? category) {
    int baseCalories = 0;

    // Calories de base par catégorie
    switch (category?.toLowerCase()) {
      case 'beef':
      case 'lamb':
      case 'pork':
        baseCalories = 500;
        break;
      case 'chicken':
        baseCalories = 350;
        break;
      case 'seafood':
        baseCalories = 300;
        break;
      case 'vegetarian':
      case 'vegan':
        baseCalories = 250;
        break;
      case 'pasta':
        baseCalories = 450;
        break;
      case 'dessert':
        baseCalories = 400;
        break;
      case 'breakfast':
        baseCalories = 350;
        break;
      default:
        baseCalories = 350;
    }

    // Ajustement basé sur le nombre d'ingrédients
    int ingredientBonus = ingredients.length * 20;

    return baseCalories + ingredientBonus;
  }

  // Calcul des macronutriments estimés (en grammes)
  Map<String, double> get estimatedMacros {
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    // Estimation basée sur la catégorie
    switch (category.toLowerCase()) {
      case 'beef':
      case 'lamb':
      case 'pork':
        protein = 35;
        fat = 25;
        carbs = 15;
        break;
      case 'chicken':
        protein = 40;
        fat = 15;
        carbs = 20;
        break;
      case 'seafood':
        protein = 30;
        fat = 10;
        carbs = 25;
        break;
      case 'vegetarian':
      case 'vegan':
        protein = 15;
        fat = 10;
        carbs = 45;
        break;
      case 'pasta':
        protein = 20;
        fat = 15;
        carbs = 60;
        break;
      case 'dessert':
        protein = 8;
        fat = 20;
        carbs = 55;
        break;
      case 'breakfast':
        protein = 25;
        fat = 18;
        carbs = 40;
        break;
      default:
        protein = 25;
        fat = 15;
        carbs = 35;
    }

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  // Distribution nutritionnelle en pourcentage
  Map<String, double> get nutritionDistribution {
    final macros = estimatedMacros;
    final totalCals = (macros['protein']! * 4) +
        (macros['carbs']! * 4) +
        (macros['fat']! * 9);

    return {
      'protein': ((macros['protein']! * 4) / totalCals * 100),
      'carbs': ((macros['carbs']! * 4) / totalCals * 100),
      'fat': ((macros['fat']! * 9) / totalCals * 100),
    };
  }

  // Conversion en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories,
      'imageUrl': imageUrl,
      'category': category,
      'isFavorite': isFavorite,
      'area': area,
      'tags': tags,
      'youtubeUrl': youtubeUrl,
      'sourceUrl': sourceUrl,
      'instructions': instructions,
      'ingredients': ingredients?.map((i) => {
        'id': i.id,
        'name': i.name,
        'measure': i.measure,
        'imageUrl': i.imageUrl,
      }).toList(),
    };
  }

  // Constructeur depuis JSON local
  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<Ingredient>? ingredients;
    if (json['ingredients'] != null) {
      ingredients = (json['ingredients'] as List)
          .map((i) => Ingredient(
        id: i['id'] as int,
        name: i['name'] as String,
        measure: i['measure'] as String,
        imageUrl: i['imageUrl'] as String,
      ))
          .toList();
    }

    return Recipe(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      calories: json['calories'] as int,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      area: json['area'] as String?,
      tags: json['tags'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      instructions: json['instructions'] as String?,
      ingredients: ingredients,
    );
  }
}

// Classe pour les ingrédients
class Ingredient {
  final int id;
  final String name;
  final String measure;
  final String imageUrl;

  Ingredient({
    required this.id,
    required this.name,
    required this.measure,
    required this.imageUrl,
  });

  String get displayText => measure.isNotEmpty ? '$measure $name' : name;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'measure': measure,
      'imageUrl': imageUrl,
    };
  }
}