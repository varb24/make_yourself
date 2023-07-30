import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/*Note: Flutter works with logical pixels as a unit of length. They are also sometimes called device-independent pixels. A padding of 8 pixels is visually the same regardless of whether the app is running on an old low-res phone or a newer ‘retina' device. There are roughly 38 logical pixels per centimeter, or about 96 logical pixels per inch, of the physical display.
 */
void main() {
  runApp(MyApp());
}

//MyApp Sets up the app
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
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 34, 255, 200)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var daysTracker = <IconData>[];
  final currentDay = DateTime.timestamp();
  int lastDayFilled = 6;
  DateTime lastDay;
  late final Duration
      difference; //This needs to read the last day from somewhere
  MyAppState() : lastDay = DateTime.now() {
    difference = currentDay.difference(lastDay);
    print(difference.inDays);
    //Fills empty daysTracker on first open
    //Need to store last dayfilled
    if (daysTracker.length < 31) {
      for (int i = 0; i < 31; i++) {
        daysTracker.add(Icons.help_outline);
      }
    }
  }

  //print(difference.inDays); Prints difference in Days.

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleDay() {
    daysTracker[lastDayFilled] = Icons.check;
    saveCard(daysTracker);
    notifyListeners();
  }

  List<IconData> getDays() {
    return daysTracker;
  }
}

class CardData {
  String date;
  String alias;

  CardData({required this.date, required this.alias});

  CardData.fromJson(Map<String, dynamic> data)
      : date = data['name'],
        alias = data['alias'];
}

Future<void> saveCard(List<IconData> myCard) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //Exception has occurred. JsonUnsupportedObjectError (Converting object to an encodable object failed: Instance of 'IconData')
  //Card jsonInput = Card() TODO make card create object...need to think about app engineering some more
  String jsonString = jsonEncode(myCard);
  await prefs.setString('my_card_key', jsonString);
}

Future<List<IconData>> loadList() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('my_card_key');
  if (jsonString != null) {
    List<dynamic> jsonList = jsonDecode(jsonString);
    return List<IconData>.from(jsonList);
  } else {
    return [];
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
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            //Expanded widgets are greedy and take up as much space as they're allowed
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

class FavoritesPage extends ListView {
  FavoritesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var fillDays = appState.getDays();
    int days = 31;

    if (fillDays.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text('You have ' '${fillDays.length} favorites:'),
      ),
      Wrap(
        spacing: .5, // gap between adjacent chips
        runSpacing: .5, // gap between lines
        children: <Widget>[
          for (int i = 0; i < days; i++)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 2.0,
                ),
              ),
              child: Icon(
                fillDays[i],
              ),
            ),
        ],
      )
    ]);
  }
}

class BoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black // Set the X color
      ..strokeWidth = 2.0; // Set the X stroke width

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(BoxPainter oldDelegate) => false;
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.daysTracker.contains(Icons.help_outline)) {
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
                  appState.toggleDay();
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
  Card build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      height: .5,
      letterSpacing: 2,
    );

    return Card(
      color: theme.colorScheme.primary,
      shadowColor: Color.fromARGB(255, 219, 100, 255),
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          "${pair.first} ${pair.second}",
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
