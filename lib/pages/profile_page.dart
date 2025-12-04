import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../widgets/custom_drawer.dart';
import '../service/imgbb_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;

  // Controllers for editing
  final TextEditingController _usernameController = TextEditingController();

  // Image picker
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Profile data
  String _username = '';
  String _email = '';
  String _imageUrl = '';
  String? _dietType;
  String? _goal;
  String? _experienceLevel;
  List<String> _allergies = [];
  final List<String> _newAllergies = [];

  // Options for dropdowns
  final List<String> _dietTypes = [
    'Omnivore',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-free',
    'Ketogenic',
    'Paleo',
  ];

  final List<String> _goals = [
    'Weight loss',
    'Muscle gain',
    'Maintenance',
    'General health',
    'Sports performance',
  ];

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  final List<String> _commonAllergies = [
    'Peanuts',
    'Tree nuts',
    'Milk',
    'Eggs',
    'Soy',
    'Wheat',
    'Fish',
    'Shellfish',
    'Sesame',
    'Mustard',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _username = data['username'] ?? 'User';
          _email = user.email ?? data['email'] ?? '';
          _imageUrl = data['imageUrl'] ?? '';

          final dietTypeRaw = data['dietType'] ?? '';
          _dietType = (dietTypeRaw.isEmpty ||
              dietTypeRaw == 'Not specified' ||
              dietTypeRaw == 'No Restrictions' ||
              !_dietTypes.contains(dietTypeRaw)) ? null : dietTypeRaw;

          final goalRaw = data['goal'] ?? '';
          _goal = (goalRaw.isEmpty ||
              goalRaw == 'Not specified' ||
              goalRaw == 'No Restrictions' ||
              !_goals.contains(goalRaw)) ? null : goalRaw;

          final experienceRaw = data['experienceLevel'] ?? '';
          _experienceLevel = (experienceRaw.isEmpty ||
              experienceRaw == 'Not specified' ||
              experienceRaw == 'No Restrictions' ||
              !_experienceLevels.contains(experienceRaw)) ? null : experienceRaw;

          _allergies = List<String>.from(data['allergies'] ?? []);

          _usernameController.text = _username;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });

        _showSnackBar('✅ Image selected: ${pickedFile.name}');
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    if (!ImgBBService.isConfigured()) {
      _showSnackBar('ImgBB API key not configured', isError: true);
      return null;
    }

    try {
      setState(() => _isUploadingImage = true);

      final imageUrl = await ImgBBService.uploadImage(_imageFile!);

      if (imageUrl != null) {
        _showSnackBar('✅ Image uploaded successfully');
        return imageUrl;
      } else {
        _showSnackBar('Failed to upload image', isError: true);
        return null;
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', isError: true);
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Upload new image if selected
      String? newImageUrl;
      if (_imageFile != null) {
        newImageUrl = await _uploadImage();
        if (newImageUrl == null) {
          _showSnackBar('Profile update cancelled: image upload failed', isError: true);
          return;
        }
      }

      final allAllergies = [..._allergies, ..._newAllergies];

      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'imageUrl': newImageUrl ?? _imageUrl,
        'dietType': _dietType ?? '',
        'goal': _goal ?? '',
        'experienceLevel': _experienceLevel ?? '',
        'allergies': allAllergies,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await user.updateDisplayName(_usernameController.text.trim());
      if (newImageUrl != null) {
        await user.updatePhotoURL(newImageUrl);
      }

      setState(() {
        _username = _usernameController.text.trim();
        if (newImageUrl != null) {
          _imageUrl = newImageUrl;
        }
        _allergies = allAllergies;
        _newAllergies.clear();
        _imageFile = null;
        _imageBytes = null;
        _isEditing = false;
      });

      _showSnackBar('✅ Profile updated successfully');
    } catch (e) {
      _showSnackBar('❌ Error updating profile: $e', isError: true);
    }
  }

  void _addAllergy(String allergy) {
    if (!_allergies.contains(allergy) && !_newAllergies.contains(allergy)) {
      setState(() {
        _newAllergies.add(allergy);
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
      _newAllergies.remove(allergy);
    });
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
              'This action is irreversible and will delete:\n'
              '• Your personal information\n'
              '• Your favorite recipes\n'
              '• Your pantry\n'
              '• All your data',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await _firestore.collection('users').doc(user.uid).delete();

      final favorites = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (var doc in favorites.docs) {
        await doc.reference.delete();
      }

      final pantry = await _firestore
          .collection('pantry')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (var doc in pantry.docs) {
        await doc.reference.delete();
      }

      await user.delete();

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showSnackBar('❌ Error deleting account: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddAllergyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add an Allergy'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _commonAllergies.length,
            itemBuilder: (context, index) {
              final allergy = _commonAllergies[index];
              final isSelected = _allergies.contains(allergy) || _newAllergies.contains(allergy);

              return ListTile(
                title: Text(allergy),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.add_circle_outline, color: Colors.grey),
                enabled: !isSelected,
                onTap: isSelected ? null : () {
                  _addAllergy(allergy);
                  Navigator.pop(context);
                  _showSnackBar('✅ Allergy "$allergy" added');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        drawer: const CustomDrawer(currentRoute: '/profil'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isUploadingImage
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save, color: Color(0xFF8BC34A)),
              onPressed: _isUploadingImage ? null : _updateProfile,
              tooltip: 'Save',
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _usernameController.text = _username;
                  _newAllergies.clear();
                  _imageFile = null;
                  _imageBytes = null;
                }
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'Cancel' : 'Edit',
          ),
        ],
      ),
      drawer: const CustomDrawer(currentRoute: '/profil'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with profile picture
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8BC34A),
                    Color(0xFF689F38),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : (_imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null) as ImageProvider?,
                        child: (_imageBytes == null && _imageUrl.isEmpty)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF8BC34A),
                                  size: 20
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (_isEditing && _imageFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'New image selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information', Icons.person),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _usernameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Nutritional Goals', Icons.restaurant_menu),
                  const SizedBox(height: 12),

                  // Diet type
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Diet type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.restaurant),
                      filled: true,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                    ),
                    child: _isEditing
                        ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _dietType,
                        isExpanded: true,
                        hint: const Text('Not specified'),
                        items: _dietTypes.map((diet) =>
                            DropdownMenuItem<String>(
                                value: diet,
                                child: Text(diet)
                            )
                        ).toList(),
                        onChanged: (value) {
                          setState(() => _dietType = value);
                        },
                      ),
                    )
                        : Text(_dietType ?? 'Not specified'),
                  ),
                  const SizedBox(height: 16),

                  // Goal
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Goal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.flag),
                      filled: true,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                    ),
                    child: _isEditing
                        ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _goal,
                        isExpanded: true,
                        hint: const Text('Not specified'),
                        items: _goals.map((goal) =>
                            DropdownMenuItem<String>(
                                value: goal,
                                child: Text(goal)
                            )
                        ).toList(),
                        onChanged: (value) {
                          setState(() => _goal = value);
                        },
                      ),
                    )
                        : Text(_goal ?? 'Not specified'),
                  ),
                  const SizedBox(height: 16),

                  // Experience level
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Experience level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.star),
                      filled: true,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                    ),
                    child: _isEditing
                        ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _experienceLevel,
                        isExpanded: true,
                        hint: const Text('Not specified'),
                        items: _experienceLevels.map((level) =>
                            DropdownMenuItem<String>(
                                value: level,
                                child: Text(level)
                            )
                        ).toList(),
                        onChanged: (value) {
                          setState(() => _experienceLevel = value);
                        },
                      ),
                    )
                        : Text(_experienceLevel ?? 'Not specified'),
                  ),
                  const SizedBox(height: 24),

                  // Allergies
                  _buildSectionTitle('Allergies', Icons.warning_amber),
                  const SizedBox(height: 12),

                  if (_allergies.isEmpty && _newAllergies.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No allergies specified',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._allergies.map((allergy) => _buildAllergyChip(allergy, false)),
                        ..._newAllergies.map((allergy) => _buildAllergyChip(allergy, true)),
                      ],
                    ),

                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showAddAllergyDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add an allergy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8BC34A),
                        side: const BorderSide(color: Color(0xFF8BC34A)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF558B2F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF558B2F),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyChip(String allergy, bool isNew) {
    return Chip(
      label: Text(allergy),
      backgroundColor: isNew ? Colors.orange.shade50 : Colors.red.shade50,
      labelStyle: TextStyle(
        color: isNew ? Colors.orange.shade700 : Colors.red.shade700,
        fontWeight: FontWeight.w500,
      ),
      deleteIcon: _isEditing
          ? Icon(Icons.close, size: 18, color: isNew ? Colors.orange.shade700 : Colors.red.shade700)
          : null,
      onDeleted: _isEditing ? () => _removeAllergy(allergy) : null,
      avatar: Icon(
          Icons.warning_amber,
          size: 18,
          color: isNew ? Colors.orange.shade700 : Colors.red.shade700
      ),
    );
  }
}