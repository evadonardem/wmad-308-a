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
        title: 'Ganado, Linson',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 10, 139, 21)),
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

  void toggleDislike() {
    if (dislikes.contains(current)) {
      dislikes.remove(current);
    } else {
      dislikes.add(current);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }

  void removeDislike(WordPair pair) {
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
                  NavigationRailDestination(
                    icon: Icon(Icons.info),
                    label: Text('About Me'), // New "About Me" option
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

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
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
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleDislike();
                },
                icon: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: appState.dislikes.contains(pair)
                      ? Icon(
                          Icons.thumb_down,
                          key: ValueKey('dislike'),
                        )
                      : Icon(
                          Icons.thumb_up_off_alt,
                          key: ValueKey('not_dislike'),
                        ),
                ),
                label: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: appState.dislikes.contains(pair)
                      ? Text('Disliked', key: ValueKey('disliked'))
                      : Text('Dislike', key: ValueKey('not_disliked')),
                ),
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
                appState.removeFavorite(pair); 
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
                appState.removeDislike(pair); 
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedContainer(
          duration: Duration(seconds: 2),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 18, 117, 48),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: Duration(seconds: 2),
                opacity: 1.0,
                child: Icon(
                  Icons.account_circle,
                  size: 100,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: 20),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 500),
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                child: Text('Linson Ganado'),
              ),
              SizedBox(height: 20),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 500),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: const Color.fromARGB(255, 3, 3, 3),
                    ),
                child: Text(
                  'This is a simple Flutter app that helps you generate random word pairs and allows you to save them to your favorites or dislikes. The app uses the Provider package for state management.',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 500),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: const Color.fromARGB(255, 3, 2, 2),
                    ),
                child: Text('Thank you for using my app!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
