import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatelessWidget {
  final String? currentRoute;

  const CustomDrawer({
    super.key,
    this.currentRoute,
  });

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header du drawer avec profil utilisateur
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots()
                    : null,
                builder: (context, snapshot) {
                  String username = 'Utilisateur';
                  String email = user?.email ?? '';
                  String imageUrl = '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    username = data['username'] ?? 'Utilisateur';
                    email = data['email'] ?? user?.email ?? '';
                    imageUrl = data['imageUrl'] ?? '';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Photo de profil
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey.shade400,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8BC34A),
                                  ),
                                ),
                              );
                            },
                          )
                              : Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Nom d'utilisateur
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Menu items
            _DrawerMenuItem(
              icon: Icons.home_outlined,
              title: 'Accueil',
              isSelected: currentRoute == '/home',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/home') {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
            ),

            _DrawerMenuItem(
              icon: Icons.kitchen_outlined,
              title: 'Pantry',
              isSelected: currentRoute == '/pantry',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/pantry') {
                  Navigator.pushReplacementNamed(context, '/pantry');
                }
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
                if (currentRoute != '/profil') {
                  Navigator.pushReplacementNamed(context, '/profil');
                }
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),

            _DrawerMenuItem(
              icon: Icons.help_outline,
              title: 'Aide',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _DrawerMenuItem(
              icon: Icons.info_outline,
              title: 'À propos',
              onTap: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
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