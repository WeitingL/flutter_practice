import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey; // Use the states to storage the data by key.

  void getNext() {
    // Stroage the history words.
    history.insert(0, current);
    var historyList = historyListKey?.currentState as AnimatedListState?;
    historyList?.insertItem(0);

    // Update the words.
    current = WordPair.random();
    notifyListeners(); // Update the data on UI.
  }

  // Storage the favorite words.
  var favorites = <WordPair>[];
  void toggleFavorite([WordPair? pair]) {
    // Accept null
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
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
      default:
        throw UnimplementedError("No widget index! $selectedIndex");
    }

    var mainLayout = ColoredBox(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200), child: page));

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          return Column(
            children: [
              Expanded(child: mainLayout),
              SafeArea(
                  child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                      icon: Icon(Icons.home), label: Text("home")),
                  NavigationRailDestination(
                      icon: Icon(Icons.favorite), label: Text("favorite"))
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ))
            ],
          );
        } else {
          return Row(
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
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(child: mainLayout),
            ],
          );
        }
      }),
    );
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
          Expanded(flex: 3, child: HistoryListView()),
          SizedBox(
            height: 20,
          ),
          BigCard(pair: pair),
          SizedBox(height: 20), // Like the spacer
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  icon: Icon(icon),
                  label: Text("Like")),
              SizedBox(width: 20),
              ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: Text("Next")),
            ],
          ),
          Spacer(
            flex: 2,
          )
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text("No favorites yet!"),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text("There are/is ${appState.favorites.length} favorites:"),
        ),
        for (var pair in appState.favorites)
          ListTile(
              leading: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  semanticLabel: "Detete",
                ),
                color: theme.colorScheme.primary,
                onPressed: () {
                  appState.removeFavorite(pair);
                },
              ),
              title: Text(pair.asLowerCase, semanticsLabel: pair.asPascalCase))
      ],
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
    var theme = Theme.of(context);

    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase,
            style: style, semanticsLabel: pair.asPascalCase),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
// Used to get the history list by key.
  final _key = GlobalKey();

  static const Gradient _gradient = LinearGradient(
      colors: [Colors.transparent, Colors.black],
      stops: [0.0, 0.5], // means the color gradent from start to center.
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) =>
          _gradient.createShader(bounds), // apply gradent on bounds
      blendMode: BlendMode.dstIn,
      child: AnimatedList(itemBuilder: (context, index, animation) {
        final pair = appState.history[index];
        return SizeTransition(
          sizeFactor: animation,
          child: TextButton.icon(
              onPressed: () {
                appState.toggleFavorite(pair);
              },
              icon: appState.favorites.contains(pair)
                  ? Icon(Icons.favorite, size: 12)
                  : SizedBox(),
              label: Text(pair.asLowerCase, semanticsLabel: pair.asPascalCase)),
        );
      }),
    );
  }
}
