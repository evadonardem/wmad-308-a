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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 224, 72, 174)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  List<WordPair> history = [];  // To keep track of previous word pairs

  void getNext() {
    history.add(current);  // Add current word pair to history
    current = WordPair.random();
    notifyListeners();
  }

  void previous() {
    if (history.isNotEmpty) {
      current = history.removeLast();  // Get the last word pair from history
      notifyListeners();
    }
  }

  var favorites = <WordPair>[];
  var dislikes = <WordPair>[];
  var aboutme = <WordPair>[WordPair('Dudz', 'Kiniway')];  // Add the content here

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void toggleDislike() {
    if (dislikes.contains(current)) {
      dislikes.remove(current);
    } else {
      dislikes.add(current);
    }
    notifyListeners();
  }

  void deleteFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }

  void deleteDislike(WordPair pair) {
    dislikes.remove(pair);
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
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = DislikesPage();
        break;
      case 3:
        page = AboutMePage();
        break;
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
    NavigationRailDestination(  // Add the About Me page
      icon: Icon(Icons.person),
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

    IconData favoriteIcon;
    IconData dislikeIcon;
    
    if (appState.favorites.contains(pair)) {
      favoriteIcon = Icons.favorite;
    } else {
      favoriteIcon = Icons.favorite_border;
    }

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
                icon: Icon(favoriteIcon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleDislike();
                },
                icon: Icon(dislikeIcon),
                label: Text('Dislike'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.previous();  // Go back to the previous word pair
                },
                child: Text('Previous'),
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
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                appState.deleteFavorite(pair);
              },
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
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                appState.deleteDislike(pair);
              },
            ),
          ),
      ],
    );
  }
}

class AboutMePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.aboutme.isEmpty) {
      return Center(
        child: Text(
          'No information in "About Me" yet.',
          style: TextStyle(fontSize: 20, color: Colors.black54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
         
        ),
        for (var pair in appState.aboutme)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 35,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              title: Text(
                '${pair.first} ${pair.second}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'This is the "About Me" section.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
      ],
    );
  }
}

