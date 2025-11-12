import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // Navigate to landing page and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _DrawerMenuItem(
              icon: Icons.restaurant_menu_outlined,
              title: 'Mes Recettes',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers la page des recettes
              },
            ),
            _DrawerMenuItem(
              icon: Icons.favorite_outline,
              title: 'Favoris',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers la page des favoris
              },
            ),
            _DrawerMenuItem(
              icon: Icons.person_outline,
              title: 'Profil',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers la page profil
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _DrawerMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                // Navigation vers les paramètres
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            // Logout button
            _DrawerMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              iconColor: Colors.red.shade400,
              textColor: Colors.red.shade700,
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _logout(context);
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
  final Color? iconColor;
  final Color? textColor;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? const Color(0xFF8BC34A) : Colors.grey.shade700),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: textColor ?? (isSelected ? const Color(0xFF558B2F) : Colors.grey.shade800),
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