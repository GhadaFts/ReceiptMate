import 'package:flutter/material.dart';
import 'database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Manager - Équipe',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController userIdController = TextEditingController(text: 'user123');
  final TextEditingController emailController = TextEditingController(text: 'test@equipe.com');
  final TextEditingController healthTargetController = TextEditingController(text: 'Perte de poids');
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController receiptIdController = TextEditingController(text: 'recette456');

  String currentUserId = 'user123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Manager - Équipe'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👤 SECTION UTILISATEUR
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👤 Gestion Utilisateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      TextField(controller: userIdController, decoration: InputDecoration(labelText: 'User ID')),
                      TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                      TextField(controller: healthTargetController, decoration: InputDecoration(labelText: 'Objectif santé')),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => DatabaseService.createUser(
                            userIdController.text,
                            emailController.text,
                            healthTarget: healthTargetController.text
                        ),
                        child: Text('Créer Utilisateur'),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 🍅 SECTION PANTRY
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🍅 Mon Garde-Manger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      TextField(controller: ingredientController, decoration: InputDecoration(labelText: 'Ingrédient')),
                      TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Quantité')),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (ingredientController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                            DatabaseService.addToPantry(
                                currentUserId,
                                ingredientController.text,
                                quantityController.text
                            );
                            ingredientController.clear();
                            quantityController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: Text('➕ Ajouter au Garde-Manger'),
                      ),
                    ],
                  ),
                ),
              ),

              // 📋 LISTE DU GARDE-MANGER
              SizedBox(height: 10),
              Text('Mon garde-manger:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                height: 150,
                child: StreamBuilder(
                  stream: DatabaseService.getUserPantry(currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text('Chargement...');

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: Icon(Icons.kitchen, color: Colors.orange),
                          title: Text(data['ingredient']),
                          subtitle: Text('Quantité: ${data['quantity']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => DatabaseService.removeFromPantry(doc.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // ❤️ SECTION FAVORIS
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('❤️ Recettes Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      TextField(controller: receiptIdController, decoration: InputDecoration(labelText: 'ID Recette')),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => DatabaseService.addToFavorites(currentUserId, receiptIdController.text),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('❤️ Ajouter aux Favoris'),
                      ),
                    ],
                  ),
                ),
              ),

              // 📋 LISTE DES FAVORIS
              SizedBox(height: 10),
              Text('Mes recettes favorites:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                height: 120,
                child: StreamBuilder(
                  stream: DatabaseService.getUserFavorites(currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text('Chargement...');

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: Icon(Icons.favorite, color: Colors.red),
                          title: Text('Recette: ${data['receipt_id']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => DatabaseService.removeFromFavorites(doc.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}