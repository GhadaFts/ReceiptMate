import 'package:flutter/material.dart';

// Modèle pour les allergies
class Allergy {
  final String id;
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final List<String> relatedIngredients;

  Allergy({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.relatedIngredients,
  });
}

// Liste des allergies communes
class AllergyData {
  static List<Allergy> getAllergies() {
    return [
      Allergy(
        id: 'gluten',
        name: 'gluten',
        displayName: 'Gluten',
        icon: Icons.grain,
        color: Colors.brown,
        relatedIngredients: [
          'flour',
          'wheat',
          'bread',
          'pasta',
          'soy sauce',
          'barley',
          'rye',
          'oats',
          'breadcrumbs',
          'couscous',
          'semolina',
        ],
      ),
      Allergy(
        id: 'dairy',
        name: 'dairy',
        displayName: 'Produits Laitiers',
        icon: Icons.water_drop,
        color: Colors.blue,
        relatedIngredients: [
          'milk',
          'cheese',
          'butter',
          'cream',
          'yogurt',
          'yoghurt',
          'mozzarella',
          'parmesan',
          'cheddar',
          'feta',
          'ricotta',
          'mascarpone',
          'sour cream',
          'heavy cream',
          'whipped cream',
        ],
      ),
      Allergy(
        id: 'eggs',
        name: 'eggs',
        displayName: 'Œufs',
        icon: Icons.egg,
        color: Colors.orange,
        relatedIngredients: [
          'egg',
          'eggs',
          'egg yolk',
          'egg white',
          'mayonnaise',
        ],
      ),
      Allergy(
        id: 'nuts',
        name: 'nuts',
        displayName: 'Fruits à Coque',
        icon: Icons.nature,
        color: Colors.brown.shade700,
        relatedIngredients: [
          'nuts',
          'almond',
          'almonds',
          'walnut',
          'walnuts',
          'cashew',
          'cashews',
          'pistachio',
          'pistachios',
          'pecan',
          'pecans',
          'hazelnut',
          'hazelnuts',
          'peanut',
          'peanuts',
          'peanut butter',
          'macadamia',
        ],
      ),
      Allergy(
        id: 'shellfish',
        name: 'shellfish',
        displayName: 'Fruits de Mer',
        icon: Icons.set_meal,
        color: Colors.red,
        relatedIngredients: [
          'shrimp',
          'prawns',
          'crab',
          'lobster',
          'crayfish',
          'oyster',
          'oysters',
          'mussel',
          'mussels',
          'clam',
          'clams',
          'scallop',
          'scallops',
          'squid',
          'octopus',
        ],
      ),
      Allergy(
        id: 'fish',
        name: 'fish',
        displayName: 'Poisson',
        icon: Icons.phishing,
        color: Colors.blue.shade700,
        relatedIngredients: [
          'fish',
          'salmon',
          'tuna',
          'cod',
          'haddock',
          'mackerel',
          'trout',
          'sardines',
          'anchovy',
          'anchovies',
          'tilapia',
          'bass',
          'halibut',
        ],
      ),
      Allergy(
        id: 'soy',
        name: 'soy',
        displayName: 'Soja',
        icon: Icons.eco,
        color: Colors.green.shade700,
        relatedIngredients: [
          'soy',
          'soya',
          'tofu',
          'soy sauce',
          'soya sauce',
          'edamame',
          'miso',
          'tempeh',
          'soy milk',
        ],
      ),
      Allergy(
        id: 'sesame',
        name: 'sesame',
        displayName: 'Sésame',
        icon: Icons.circle,
        color: Colors.amber.shade700,
        relatedIngredients: [
          'sesame',
          'sesame oil',
          'sesame seeds',
          'tahini',
        ],
      ),
    ];
  }

  // Vérifier si une recette contient des allergènes
  static bool recipeContainsAllergen(
      List<String> ingredients,
      List<String> selectedAllergies,
      ) {
    if (selectedAllergies.isEmpty) return false;

    final allergies = getAllergies()
        .where((a) => selectedAllergies.contains(a.id))
        .toList();

    for (var allergy in allergies) {
      for (var ingredient in ingredients) {
        final ingredientLower = ingredient.toLowerCase();
        for (var allergen in allergy.relatedIngredients) {
          if (ingredientLower.contains(allergen.toLowerCase())) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Obtenir les allergènes trouvés dans une recette
  static List<String> findAllergensInRecipe(
      List<String> ingredients,
      List<String> selectedAllergies,
      ) {
    if (selectedAllergies.isEmpty) return [];

    final allergies = getAllergies()
        .where((a) => selectedAllergies.contains(a.id))
        .toList();

    List<String> foundAllergens = [];

    for (var allergy in allergies) {
      for (var ingredient in ingredients) {
        final ingredientLower = ingredient.toLowerCase();
        for (var allergen in allergy.relatedIngredients) {
          if (ingredientLower.contains(allergen.toLowerCase())) {
            if (!foundAllergens.contains(allergy.displayName)) {
              foundAllergens.add(allergy.displayName);
            }
            break;
          }
        }
      }
    }

    return foundAllergens;
  }
}