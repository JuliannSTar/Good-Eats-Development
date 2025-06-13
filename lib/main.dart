import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'spoonacular_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 174, 235, 166),
        ),
      ),
      home: const MyHomePage(title: 'Good Eats'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _recipes = [];
  bool _loading = false;
  String? _error;
  int _offset = 0;
  int _totalResults = 0;
  bool _loadingMore = false;
  String _lastQuery = '';
  Future<void> _search({bool loadMore = false}) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (!loadMore) {
      // New search → reset
      setState(() {
        _offset = 0;
        _recipes = [];
        _totalResults = 0;
        _error = null;
        _loading = true;
        _lastQuery = query;
      });
    } else {
      // Load more
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final jsonBody = await SpoonacularApi.searchRecipes(
        _lastQuery,
        offset: _offset,
      );
      final results = jsonBody['results'] as List<dynamic>;
      final totalResults = jsonBody['totalResults'] as int;

      setState(() {
        _recipes.addAll(results);
        _totalResults = totalResults;
        _offset += results.length;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Search Recipes'),
            controller: _controller,
            onSubmitted: (_) => _search(),
          ),

          SizedBox(
            width: 400.0,
            height: 40.0,
            child: ElevatedButton(
              onPressed: _search,
              child: _loading ? null : const Text('search'),
            ),
          ),
          if (_error != null) Text(_error!),
          if (_recipes.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, i) {
                        final recipe = _recipes[i] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(recipe['title']),
                            leading: recipe['image'] != null
                                ? Html(
                                    data:
                                        '<img src="${recipe['image']}" width="50" style="object-fit:cover;"/>',
                                  )
                                : null,
                            onTap: () async {
                              try {
                                final details =
                                    await SpoonacularApi.getRecipeInformation(
                                      recipe['id'],
                                    );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeInfo(recipeInfo: details),
                                  ),
                                );
                              } catch (e) {}
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (_offset < _totalResults)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed: _loadingMore
                            ? null
                            : () => _search(loadMore: true),
                        child: _loadingMore
                            ? const CircularProgressIndicator()
                            : const Text('Load More'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      //make page for recipe info when tab pressed
    );
  }
}

class RecipeInfo extends StatelessWidget {
  final Map<String, dynamic> recipeInfo;
  const RecipeInfo({super.key, required this.recipeInfo});
  @override
  Widget build(BuildContext context) {
    final _ingredients = recipeInfo['extendedIngredients'];
    return Scaffold(
      appBar: AppBar(
        title: Text("Recipe Details"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //title
            Text(
              recipeInfo['title'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    recipeInfo['image'],
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${recipeInfo['healthScore']?.toStringAsFixed(0) ?? 'N/A'}%',
                      ),
                      Text(
                        'Calories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      Text(
                        '${recipeInfo['nutrition']?['nutrients']?[0]?['amount']?.toStringAsFixed(0) ?? 'N/A'} kcal',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            //style
            const SizedBox(height: 16),
            //Calories

            //text style
            //ingredients
            SizedBox(height: 16),
            Text('Ingredients:', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            ...?_ingredients?.map((ingredient) {
              String formatAmount(num value) {
                final s = value.toStringAsFixed(2);
                return s.replaceAll(RegExp(r'\.?0+$'), '');
              }

              final rawAmount = ingredient['amount'];
              final amount = rawAmount != null
                  ? formatAmount((rawAmount as num).toDouble())
                  : '';
              final unit = ingredient['unit'] ?? '';
              final name = ingredient['name'] ?? '';
              return Text('$amount $unit $name');
            }),
            const SizedBox(height: 16),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),

            if ((recipeInfo['analyzedInstructions'] as List?) != null &&
                (recipeInfo['analyzedInstructions'] as List).isNotEmpty)
              ...((recipeInfo['analyzedInstructions'][0]['steps'] as List).map<
                Widget
              >((step) {
                final stepNumber = step['number'];
                final stepText = step['step'];

                final ingredients = step['ingredients'] as List;
                final equipment = step['equipment'] as List;

                final length = step['length'];

                return ExpansionTile(
                  title: Text('Step $stepNumber'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step text
                          Text(stepText),

                          // Optional time
                          if (length != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Time: ${length['number']} ${length['unit']}',
                              ),
                            ),

                          // Ingredients
                          if (ingredients.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Ingredients:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ingredients.map<Widget>((ingredient) {
                                final name = ingredient['name'];
                                final imageUrl =
                                    ingredient['image'] != null &&
                                        ingredient['image']
                                            .toString()
                                            .isNotEmpty
                                    ? 'https://spoonacular.com/cdn/ingredients_100x100/${ingredient['image']}'
                                    : null;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (imageUrl != null)
                                      Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                      ),
                                    Text(name, textAlign: TextAlign.center),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],

                          // Equipment
                          if (equipment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Equipment:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: equipment.map<Widget>((equip) {
                                final name = equip['name'];
                                final imageUrl =
                                    equip['image'] != null &&
                                        equip['image'].toString().isNotEmpty
                                    ? equip['image']
                                    : null;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (imageUrl != null)
                                      Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                      ),
                                    Text(name, textAlign: TextAlign.center),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList())
            else
              // fallback in case analyzedInstructions is empty
              Html(data: recipeInfo['instructions'] as String),
          ],
        ),
      ),
    );
  }
}
