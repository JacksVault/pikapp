import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String API_KEY = '3989e2bf5a734e4890f5842c177c109a';
const String API_URL = 'https://api.spoonacular.com/recipes/findByIngredients';
const String IMAGE_URL = 'https://spoonacular.com/recipeImages/';

void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatefulWidget {
  const RecipeApp({Key? key}) : super(key: key);

  @override
  _RecipeAppState createState() => _RecipeAppState();
}

class _RecipeAppState extends State<RecipeApp> {
  String ingredients = '';
  Map<String, dynamic>? recipe;
  String error = '';

  void fetchRecipe() async {
    setState(() {
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$API_URL?apiKey=$API_KEY&ingredients=${Uri.encodeComponent(ingredients)}&number=1'),
      );

      final data = jsonDecode(response.body);

      if (data != null && data is List && data.isNotEmpty) {
        final recipeId = data[0]['id'];
        final recipeResponse = await http.get(
          Uri.parse(
              'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$API_KEY'),
        );

        final detailedRecipe = jsonDecode(recipeResponse.body);
        setState(() {
          recipe = detailedRecipe;
        });
      } else {
        setState(() {
          error = 'No recipe found for the provided ingredients.';
        });
      }
    } catch (error) {
      setState(() {
        this.error = 'Error fetching data from the server.';
      });
    }
  }

  List<String> extractSteps(String? instructions) {
    if (instructions == null) return [];
    return instructions.split('\n').where((step) => step.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Recommendation'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recipe Recommendation',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter your ingredients (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    setState(() {
                      ingredients = text;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: fetchRecipe,
                  child: const Text('Get Recipe'),
                ),
                const SizedBox(height: 30),
                if (recipe != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        recipe!['title'],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (recipe!['image'] != null)
                        Image.network(
                          '$IMAGE_URL${recipe!['image']}',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 10),
                      if (recipe!['instructions'] != null)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              extractSteps(recipe!['instructions']).length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Text('${index + 1}.'),
                              title: Text(
                                  extractSteps(recipe!['instructions'])[index]),
                            );
                          },
                        ),
                    ],
                  ),
                if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
