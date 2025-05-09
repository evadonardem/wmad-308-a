import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];
  var dislikes = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void toggleDislikes() {
    if (dislikes.contains(current)) {
      dislikes.remove(current);
    } else {
      dislikes.add(current);
    }
    notifyListeners();
  }

  void toggleRemoveFromFavorites(var pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    }
    notifyListeners();
  }

  void toggleRemoveFromDislikes(var pair) {
    if (dislikes.contains(pair)) {
      dislikes.remove(pair);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      case 2:
        page = DislikesPage();
      case 3:
        page = AboutMePage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.thumb_down),
                    label: Text('Dislikes'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.info),
                    label: Text('About Me'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData likeIcon;
    if (appState.favorites.contains(pair)) {
      likeIcon = Icons.favorite;
    } else {
      likeIcon = Icons.favorite_border;
    }

    IconData dislikeIcon;
    if (appState.dislikes.contains(pair)) {
      dislikeIcon = Icons.thumb_down;
    } else {
      dislikeIcon = Icons.thumb_down_alt_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(likeIcon),
                label: Text('I like this'),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleDislikes();
                },
                icon: Icon(dislikeIcon),
                label: Text("I don't like this"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    IconData deleteIcon = Icons.delete;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
            trailing: ElevatedButton.icon(
              onPressed: () {
                appState.toggleRemoveFromFavorites(pair);
              },
              icon: Icon(deleteIcon),
              label: Text("Remove"),
            ),
          ),
      ],
    );
  }
}

class DislikesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.dislikes.isEmpty) {
      return Center(
        child: Text('No dislikes yet.'),
      );
    }

    IconData deleteIcon = Icons.delete;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.dislikes.length} dislikes:'),
        ),
        for (var pair in appState.dislikes)
          ListTile(
            leading: Icon(Icons.thumb_down),
            title: Text(pair.asLowerCase),
            trailing: ElevatedButton.icon(
              onPressed: () {
                appState.toggleRemoveFromDislikes(pair);
              },
              icon: Icon(deleteIcon),
              label: Text("Remove"),
            ),
          ),
      ],
    );
  }
}

class AboutMePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    var appState = context.watch<MyAppState>();
    var favoriteString = <String>[];
    var dislikeString = <String>[];

    for (var pair in appState.favorites) {
      favoriteString.add(pair.asPascalCase);
    }
    
    for (var pair in appState.dislikes) {
      dislikeString.add(pair.asPascalCase);
    }

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Card(
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "I am Melbert Marafo",
                  style: style,
                  semanticsLabel: "I am Melbert Marafo",
                ),
              ),
            ),
            Text(
              "I like ${favoriteString.join(", ")}"
            ),
            Text("I don't like ${dislikeString.join(", ")}"),
          ],
        ),
    );
  }
}
