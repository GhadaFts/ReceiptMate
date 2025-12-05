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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
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
            content: Text('Logout error: ${e.toString()}'),
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
        child: Column(
          children: [
            // Header du drawer avec logo et app name
            Container(
              padding: const EdgeInsets.all(24.0),
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
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 35,
                        color: const Color(0xFF689F38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App name
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Recipe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.orange.shade100,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const TextSpan(
                            text: 'Mate',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
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
                    title: 'Favorites',
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
                    title: 'Profile',
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
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _DrawerMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.red.shade400,
                      textColor: Colors.red.shade700,
                      onTap: () {
                        Navigator.pop(context);
                        _logout(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // User profile at the bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
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
                  String username = 'User';
                  String email = user?.email ?? '';
                  String imageUrl = '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    username = data['username'] ?? 'User';
                    email = data['email'] ?? user?.email ?? '';
                    imageUrl = data['imageUrl'] ?? '';
                  }

                  return Row(
                    children: [
                      // Profile image with welcome text
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30,
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
                            size: 30,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Welcome, ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),

                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Profile button
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/profil');
                        },
                        tooltip: 'Go to profile',
                      ),
                    ],
                  );
                },
              ),
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