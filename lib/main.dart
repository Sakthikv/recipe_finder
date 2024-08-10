import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MealFinderApp());
}

class MealFinderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Find Meal For Your Ingredients',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MealFinderPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            Image.asset('images/Recipe2.jpeg'), // Replace with your image path
      ),
    );
  }
}

class MealFinderPage extends StatefulWidget {
  @override
  _MealFinderPageState createState() => _MealFinderPageState();
}

class _MealFinderPageState extends State<MealFinderPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _mealList = [];
  String _errorMessage = '';
  bool _usingThemealdb = true;

  Future<void> _getMealList() async {
    String searchInputTxt = _searchController.text.trim();
    if (searchInputTxt.isEmpty) return;

    final themealdbUrl =
        'https://www.themealdb.com/api/json/v1/1/filter.php?i=$searchInputTxt';
    final edamamUrl =
        'https://api.edamam.com/search?q=$searchInputTxt&app_id=fdfc54fb&app_key=f7ccdf6932dcc53528ea2248cad02b36';

    try {
      final response = await http.get(Uri.parse(themealdbUrl));
      final data = json.decode(response.body);

      if (data != null && data['meals'] != null && data['meals'] is List) {
        setState(() {
          _mealList = data['meals'];
          _errorMessage = '';
          _usingThemealdb = true;
        });
      } else {
        final edamamResponse = await http.get(Uri.parse(edamamUrl));
        final edamamData = json.decode(edamamResponse.body);
        if (edamamData != null &&
            edamamData['hits'] != null &&
            edamamData['hits'] is List &&
            edamamData['hits'].isNotEmpty) {
          setState(() {
            _mealList = edamamData['hits'];
            _errorMessage = '';
            _usingThemealdb = false;
          });
        } else {
          setState(() {
            _mealList = [];
            _errorMessage = 'No results found.';
          });
        }
      }
    } catch (error) {
      setState(() {
        _mealList = [];
        _errorMessage = 'Error fetching data.';
      });
    }
  }

  Future<void> _fetchMealRecipe(String id) async {
    final themealdbUrl =
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id';

    try {
      final response = await http.get(Uri.parse(themealdbUrl));
      final data = json.decode(response.body);
      if (data != null && data['meals'] != null && data['meals'].isNotEmpty) {
        _showRecipeModal(context, data['meals'][0], true);
      } else {
        setState(() {
          _errorMessage = 'Recipe details not found.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error fetching recipe details.';
      });
    }
  }

  Future<void> _fetchEdamamRecipe(String uri) async {
    final encodedUri = Uri.encodeComponent(uri);
    final edamamUrl =
        'https://api.edamam.com/search?r=$encodedUri&app_id=fdfc54fb&app_key=f7ccdf6932dcc53528ea2248cad02b36';

    try {
      final response = await http.get(Uri.parse(edamamUrl));
      final data = json.decode(response.body);
      if (data != null && data is List && data.isNotEmpty) {
        _showRecipeModal(context, data[0], false); // data[0] is the recipe
      } else {
        setState(() {
          _errorMessage = 'Recipe details not found.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error fetching recipe details.';
      });
    }
  }

  void _showRecipeModal(BuildContext context, dynamic meal, bool isThemealdb) {
    final videoUrl = isThemealdb ? meal['strYoutube'] : meal['url'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(meal['strMeal'] ?? meal['label'] ?? 'No title'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal['strMealThumb'] != null || meal['image'] != null)
                  Image.network(meal['strMealThumb'] ?? meal['image']),
                SizedBox(height: 10),
                Text(
                  meal['strInstructions'] ??
                      (meal['ingredientLines']?.join(', ') ??
                          'No instructions available'),
                ),
                SizedBox(height: 10),
                if (videoUrl != null && videoUrl.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      _launchURL(videoUrl);
                    },
                    child: Text('Watch Video'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text('Find Meals For Your Ingredients'),
          ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter an ingredient or food',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.orange[50],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              ),
              onSubmitted: (value) => _getMealList(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _mealList.isNotEmpty
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio:
                            0.75, // Adjust the aspect ratio as needed
                      ),
                      itemCount: _mealList.length,
                      itemBuilder: (context, index) {
                        final meal = _mealList[index];
                        return GestureDetector(
                          onTap: () {
                            if (_usingThemealdb) {
                              _fetchMealRecipe(meal['idMeal']);
                            } else {
                              _fetchEdamamRecipe(meal['recipe']['uri']);
                            }
                          },
                          child: Card(
                            elevation: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _usingThemealdb
                                      ? Image.network(
                                          meal['strMealThumb'],
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          meal['recipe']['image'],
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _usingThemealdb
                                        ? meal['strMeal']
                                        : meal['recipe']['label'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : Center(
                          child: Text(
                          "Your Search Result",
                          style: TextStyle(color: Colors.orange, fontSize: 25),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
