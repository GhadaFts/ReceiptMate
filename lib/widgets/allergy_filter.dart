import 'package:flutter/material.dart';
import '../models/allergy.dart';

class AllergyFilterSheet extends StatefulWidget {
  final List<String> selectedAllergies;
  final Function(List<String>) onAllergiesChanged;

  const AllergyFilterSheet({
    super.key,
    required this.selectedAllergies,
    required this.onAllergiesChanged,
  });

  @override
  State<AllergyFilterSheet> createState() => _AllergyFilterSheetState();
}

class _AllergyFilterSheetState extends State<AllergyFilterSheet> {
  late List<String> _selectedAllergies;

  @override
  void initState() {
    super.initState();
    _selectedAllergies = List.from(widget.selectedAllergies);
  }

  @override
  Widget build(BuildContext context) {
    final allergies = AllergyData.getAllergies();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Filtrer par allergies',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedAllergies.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedAllergies.clear();
                      });
                    },
                    child: const Text('Tout effacer'),
                  ),
              ],
            ),
          ),

          // Liste des allergies
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: allergies.length,
              itemBuilder: (context, index) {
                final allergy = allergies[index];
                final isSelected = _selectedAllergies.contains(allergy.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AllergyCard(
                    allergy: allergy,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedAllergies.remove(allergy.id);
                        } else {
                          _selectedAllergies.add(allergy.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAllergiesChanged(_selectedAllergies);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedAllergies.isEmpty
                          ? 'Appliquer'
                          : 'Appliquer (${_selectedAllergies.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllergyCard extends StatelessWidget {
  final Allergy allergy;
  final bool isSelected;
  final VoidCallback onTap;

  const AllergyCard({
    super.key,
    required this.allergy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? allergy.color.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? allergy.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? allergy.color
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                allergy.icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allergy.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? allergy.color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allergy.relatedIngredients.length} ingrédients',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? allergy.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? allergy.color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget badge pour afficher les allergies actives
class AllergyBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const AllergyBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: count > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: count > 0 ? Colors.orange : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: count > 0 ? Colors.orange : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$count allergie${count > 1 ? 's' : ''}' : 'Allergies',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: count > 0 ? Colors.orange.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}