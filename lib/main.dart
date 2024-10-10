import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp()); // Entry point of the Flutter app
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Setting up the main app UI, defining the theme and homepage
    return MaterialApp(
      title: 'Preeda Cocktails', // App title
      theme: ThemeData(
        primarySwatch: Colors.purple, // Primary color theme
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            color: Colors.black, // Setting default text color
          ),
        ),
      ),
      home: HomeScreen(), // Main screen of the app
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState(); // Define the state
}

class _HomeScreenState extends State<HomeScreen> {
  // API-related variables for Google Sheets
  final String apiKey = 'YOUR_GOOGLE_API_KEY';
  final String spreadsheetId = 'YOUR_GOOGLE_SPREADSHEET_ID';
  final String range = 'Sheet1!A:I';
  List<dynamic> cocktails = []; // To store cocktail data from the API
  List<dynamic> filteredCocktails = []; // Store filtered search results
  List<String> genres = []; // List of unique genres
  bool isLoading = true; // Loading state indicator

  TextEditingController searchController =
      TextEditingController(); // Search input controller

  @override
  void initState() {
    super.initState();
    fetchCocktails(); // Fetch cocktails on app start
  }

  // Fetch data from Google Sheets using the API
  Future<void> fetchCocktails() async {
    final url =
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Decode JSON response

      setState(() {
        cocktails = data['values'].skip(1).toList(); // Skip header row
        filteredCocktails = cocktails; // Set filtered list to the full list

        // Extract unique genres from column 8
        genres = cocktails
            .map((cocktail) => cocktail[8].toString())
            .toSet()
            .toList();

        isLoading = false; // End loading state
      });
    } else {
      throw Exception('Failed to load data'); // Handle error
    }
  }

  // Filter cocktails by search query
  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCocktails = cocktails; // Show all cocktails if no query
      } else {
        filteredCocktails = cocktails.where((cocktail) {
          final cocktailName = cocktail[0].toLowerCase();
          final ingredients = cocktail[4].toLowerCase();
          final searchQuery = query.toLowerCase();

          // Match cocktail name or ingredients to query
          return cocktailName.contains(searchQuery) ||
              ingredients.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Genre or Search for a Drink'), // Page title
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loader while fetching data
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'lib/images/Preeda_Restaurant_Berlin_Logo_200.png', // App logo
                    width: 200,
                    height: 100,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearchResults, // Handle search input
                    decoration: InputDecoration(
                      labelText: "Search for a cocktail...",
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.grey[400]),
                        onPressed: () {
                          filterSearchResults(searchController
                              .text); // Trigger search on button press
                        },
                      ),
                    ),
                    style:
                        TextStyle(color: Colors.black), // Style the input text
                  ),
                ),
                Expanded(
                  // Show genres or search results based on input
                  child: searchController.text.isEmpty
                      ? buildGenreListView() // List of genres if no search query
                      : buildCocktailGridView(), // Grid of cocktails if search query exists
                ),
              ],
            ),
    );
  }

  // Build a list of genres
  Widget buildGenreListView() {
    return ListView.builder(
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return GenreButton(
          genre: genre,
          onTap: () =>
              navigateToGenre(context, genre), // Navigate to selected genre
        );
      },
    );
  }

  // Build a grid view of cocktails
  Widget buildCocktailGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two items per row
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75, // Image and text layout ratio
      ),
      itemCount: filteredCocktails.length,
      itemBuilder: (context, index) {
        final cocktail = filteredCocktails[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CocktailDetailScreen(
                    cocktail: cocktail), // Navigate to details
              ),
            );
          },
          child: Card(
            elevation: 4.0, // Card shadow effect
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: cocktail[3] != null && cocktail[3].isNotEmpty
                          ? Image.network(cocktail[3],
                              fit: BoxFit.cover) // Display image if available
                          : Icon(Icons.local_bar,
                              size: 100), // Fallback icon if no image
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black
                        .withOpacity(0.6), // Semi-transparent background
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Text(
                      cocktail[0], // Cocktail name
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white, // White text on black background
                        fontWeight: FontWeight.bold, // Bold for emphasis
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigate to selected genre's cocktail list
  void navigateToGenre(BuildContext context, String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CocktailListScreen(genre: genre, cocktails: cocktails),
      ),
    );
  }
}

// Button widget for genre selection
class GenreButton extends StatelessWidget {
  final String genre;
  final VoidCallback onTap;

  const GenreButton({required this.genre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ElevatedButton(
        onPressed: onTap, // Trigger the callback on button press
        child: Text(
          genre, // Genre label
          style: TextStyle(
            fontSize: 18,
            color: Colors.white, // White text for readability
            fontWeight: FontWeight.bold, // Bold for contrast
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          padding: EdgeInsets.symmetric(vertical: 16.0), // Button padding
          backgroundColor: Colors.purple, // Button background color
          shadowColor: Colors.black, // Shadow effect
          elevation: 5, // Elevation for depth
        ),
      ),
    );
  }
}

// Screen displaying list of cocktails filtered by genre
class CocktailListScreen extends StatelessWidget {
  final String genre;
  final List<dynamic> cocktails;

  const CocktailListScreen({required this.genre, required this.cocktails});

  @override
  Widget build(BuildContext context) {
    // Filter cocktails by genre
    List<dynamic> genreCocktails = cocktails
        .where(
            (cocktail) => cocktail[8] == genre) // Filter by genre in column 8
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cocktails: $genre'), // Page title showing genre
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two items per row
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75, // Aspect ratio of items
        ),
        itemCount: genreCocktails.length,
        itemBuilder: (context, index) {
          final cocktail = genreCocktails[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CocktailDetailScreen(
                      cocktail: cocktail), // Navigate to details
                ),
              );
            },
            child: Card(
              elevation: 4.0, // Card elevation effect
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: cocktail[3] != null && cocktail[3].isNotEmpty
                            ? Image.network(cocktail[3],
                                fit: BoxFit.cover) // Image display
                            : Icon(Icons.local_bar, size: 100), // Fallback icon
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.6), // Background transparency
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Text(
                        cocktail[0], // Cocktail name
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold, // Bold for better visibility
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Detail screen showing full cocktail details
class CocktailDetailScreen extends StatelessWidget {
  final List<dynamic> cocktail;

  const CocktailDetailScreen({required this.cocktail});

  @override
  Widget build(BuildContext context) {
    // Format ingredients into separate lines
    final ingredients = cocktail[4].split(',').map((e) => e.trim()).join('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(cocktail[0]), // Cocktail name in title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display cocktail image or icon
            cocktail[3] != null && cocktail[3].isNotEmpty
                ? Image.network(cocktail[3]) // Cocktail image
                : Icon(Icons.local_bar,
                    size: 100, color: Colors.white), // Fallback icon
            SizedBox(height: 16),

            // Cocktail name in large font
            Center(
              child: Text(
                cocktail[0], // Cocktail name
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),

            // Show genre, glass type, and main alcohol
            Center(
              child: Text(
                'Genre: ${cocktail[8]}',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            if (cocktail[1] != null && cocktail[1].isNotEmpty)
              Column(
                children: [
                  SizedBox(
                      height:
                          8), // Add spacing when the "Glass" field is present
                  Center(
                    child: Text(
                      'Glass: ${cocktail[1]}', // Display the glass type
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            else
              SizedBox
                  .shrink(), // If no "Glass" field, show nothing (empty widget)

            if (cocktail[2] != null && cocktail[2].isNotEmpty)
              Column(
                children: [
                  SizedBox(
                      height:
                          8), // Add spacing when the "Alchohol" field is present
                  Center(
                    child: Text(
                      'Glass: ${cocktail[2]}', // Display the alchohol type
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            else
              SizedBox
                  .shrink(), // If no "Glass" field, show nothing (empty widget)

            SizedBox(height: 8),

            // Display formatted ingredients
            Center(
              child: Text(
                'Ingredients:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                ingredients, // Show ingredients
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),

            // Show instructions and garnish information
            Text(
              'Instructions: ${cocktail[5]}',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Garnish: ${cocktail[6]}',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),

            // Show price
            Center(
              child: Text(
                'Price: ${cocktail[7]}',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),

            // Back button to return to the previous screen
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back'), // Button to go back
              ),
            ),
          ],
        ),
      ),
    );
  }
}
