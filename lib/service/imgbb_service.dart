import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImgBBService {
  // 🔑 REMPLACEZ avec votre clé API ImgBB
  static const String _apiKey = '491ead3a6e44b92984e543cec71a8adf';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Upload une image vers ImgBB et retourne l'URL de l'image
  /// Fonctionne sur Web, Android et iOS
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      print('📤 Début de l\'upload vers ImgBB...');

      // Lire l'image comme bytes (compatible web et mobile)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📦 Image convertie en base64 (${base64Image.length} caractères)');

      // Préparer la requête POST
      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      print('📡 Réponse reçue : ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          print('✅ Image uploadée avec succès : $imageUrl');
          return imageUrl;
        } else {
          print('❌ Erreur ImgBB : ${jsonResponse['error']}');
          return null;
        }
      } else {
        print('❌ Erreur HTTP : ${response.statusCode}');
        print('Réponse : ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'upload : $e');
      return null;
    }
  }

  /// Upload depuis des bytes directement
  static Future<String?> uploadFromBytes(Uint8List bytes, String filename) async {
    try {
      print('📤 Upload depuis bytes...');

      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
          'name': filename,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          print('✅ Image uploadée : $imageUrl');
          return imageUrl;
        } else {
          print('❌ Erreur : ${jsonResponse['error']}');
          return null;
        }
      } else {
        print('❌ Erreur HTTP : ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur : $e');
      return null;
    }
  }

  /// Vérifier si la clé API est configurée
  static bool isConfigured() {
    return _apiKey != 'VOTRE_CLE_API_ICI' && _apiKey.isNotEmpty;
  }
}