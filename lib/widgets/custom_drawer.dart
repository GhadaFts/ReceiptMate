import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String? currentRoute; // ✅ Rendre optionnel

  const CustomDrawer({
    super.key,
    this.currentRoute, // ✅ Plus required
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header du drawer avec image et nom
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8BC34A),
                    const Color(0xFF689F38),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=200',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Healthy Salads',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recettes saines et nutritives',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            _DrawerMenuItem(
              icon: Icons.home_outlined,
              title: 'Accueil',
              isSelected: currentRoute == '/home', // ✅ Utilise currentRoute si fourni
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                if (currentRoute != '/home') {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.restaurant_menu_outlined,
              title: 'Mes Recettes',
              isSelected: currentRoute == '/mes-recettes',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers la page des recettes
                // Navigator.pushNamed(context, '/mes-recettes');
              },
            ),
            _DrawerMenuItem(
              icon: Icons.favorite_outline,
              title: 'Favoris',
              isSelected: currentRoute == '/favoris',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/favoris') {
                  Navigator.pushReplacementNamed(context, '/favoris');
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.person_outline,
              title: 'Profil',
              isSelected: currentRoute == '/profil',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers la page profil
                // Navigator.pushNamed(context, '/profil');
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _DrawerMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              isSelected: currentRoute == '/parametres',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers les paramètres
                // Navigator.pushNamed(context, '/parametres');
              },
            ),
            _DrawerMenuItem(
              icon: Icons.help_outline,
              title: 'Aide',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers l'aide
              },
            ),
            _DrawerMenuItem(
              icon: Icons.info_outline,
              title: 'À propos',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers à propos
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF8BC34A) : Colors.grey.shade700,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF558B2F) : Colors.grey.shade800,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF8BC34A).withOpacity(0.1),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}