import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'spoonacular_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await SpoonacularApi.searchRecipes(query);
      setState(() {
        _recipes = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
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
              child: ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, i) {
                  final recipe = _recipes[i] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(recipe['title']),
                      leading: recipe['image'] != null
                          ? Image.network(
                              recipe['image'],
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
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
                              builder: (_) => RecipeInfo(recipeInfo: details),
                            ),
                          );
                        } catch (e) {}
                      },
                    ),
                  );
                },
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                recipeInfo['image'],
                width: 350,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            //style
            const SizedBox(height: 16),
            //Calories
            Text(
              'Calories: ${recipeInfo['nutrition']?['nutrients']?[0]?['amount'] ?? 'N/A'} kcal',
              //style),
            ),
            const SizedBox(height: 16),

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
            Html(data: recipeInfo['instructions'] as String),
          ],
        ),
      ),
    );
  }
}
