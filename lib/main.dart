import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database _database;
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<Flashcard> _cards = [];
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  String _userAnswer = '';
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  Map<int, CardStats> _stats = {};

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'flashcards.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER,
            front TEXT,
            back TEXT,
            FOREIGN KEY (category_id) REFERENCES categories (id)
          )
        ''');
        await db.execute('''
          CREATE TABLE stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id INTEGER,
            date TEXT,
            correct INTEGER,
            wrong INTEGER,
            FOREIGN KEY (card_id) REFERENCES cards (id)
          )
        ''');
      },
    );

    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    final List<Map<String, dynamic>> maps = await _database.query('categories');
    setState(() {
      _categories = List.generate(maps.length, (i) {
        return Category(
          id: maps[i]['id'],
          name: maps[i]['name'],
        );
      });
    });
  }

  Future<void> _loadCards(int categoryId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'cards',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    setState(() {
      _cards = List.generate(maps.length, (i) {
        return Flashcard(
          id: maps[i]['id'],
          categoryId: maps[i]['category_id'],
          front: maps[i]['front'],
          back: maps[i]['back'],
        );
      });
      _currentCardIndex = 0;
      _isFlipped = false;
      _userAnswer = '';
    });

    if (_cards.isNotEmpty) {
      await _loadStats(_cards.first.id);
    }
  }

  Future<void> _loadStats(int cardId) async {
    final List<Map<String, dynamic>> maps = await _database.rawQuery('''
      SELECT 
        SUM(correct) as totalCorrect,
        SUM(wrong) as totalWrong
      FROM stats
      WHERE card_id = ?
    ''', [cardId]);

    setState(() {
      _stats[cardId] = CardStats(
        totalCorrect: maps.first['totalCorrect'] ?? 0,
        totalWrong: maps.first['totalWrong'] ?? 0,
      );
    });
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) return;

    final id = await _database.insert(
      'categories',
      {'name': _categoryController.text},
    );

    setState(() {
      _categories.add(Category(id: id, name: _categoryController.text));
      _categoryController.clear();
    });
  }

  Future<void> _addCard() async {
    if (_frontController.text.trim().isEmpty ||
        _backController.text.trim().isEmpty ||
        _selectedCategory == null) return;

    final id = await _database.insert(
      'cards',
      {
        'category_id': _selectedCategory!.id,
        'front': _frontController.text,
        'back': _backController.text,
      },
    );

    setState(() {
      _cards.add(Flashcard(
        id: id,
        categoryId: _selectedCategory!.id,
        front: _frontController.text,
        back: _backController.text,
      ));
      _frontController.clear();
      _backController.clear();
    });
  }

  Future<void> _recordAnswer(bool isCorrect) async {
    if (_cards.isEmpty) return;

    final currentCardId = _cards[_currentCardIndex].id;
    final today = DateTime.now().toIso8601String().split('T')[0];

    await _database.insert(
      'stats',
      {
        'card_id': currentCardId,
        'date': today,
        'correct': isCorrect ? 1 : 0,
        'wrong': isCorrect ? 0 : 1,
      },
    );

    await _loadStats(currentCardId);
    _nextCard();
  }

  void _nextCard() {
    if (_cards.isEmpty) return;

    setState(() {
      _currentCardIndex = (_currentCardIndex + 1) % _cards.length;
      _isFlipped = false;
      _userAnswer = '';
    });

    _loadStats(_cards[_currentCardIndex].id);
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _checkAnswer() {
    if (_userAnswer.trim().isEmpty) return;

    final currentCard = _cards[_currentCardIndex];
    final isCorrect = _userAnswer.toLowerCase() == currentCard.back.toLowerCase();
    _recordAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Section
            _buildCategorySection(),
            SizedBox(height: 20),

            // Flashcard Section
            if (_selectedCategory != null) _buildFlashcardSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            // Category List
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: _selectedCategory?.id == category.id,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                          if (selected) {
                            _loadCards(category.id);
                          } else {
                            _cards = [];
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

            // Add Category
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'New category name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardSection() {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Flashcards (${_cards.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Flashcard Display
              if (_cards.isNotEmpty) _buildFlashcard(),
              if (_cards.isEmpty) _buildNoCardsMessage(),

              // Add New Card
              SizedBox(height: 20),
              _buildAddCardForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcard() {
    final currentCard = _cards[_currentCardIndex];
    final cardStats = _stats[currentCard.id] ?? CardStats(totalCorrect: 0, totalWrong: 0);

    return Expanded(
      child: Column(
        children: [
          // Flashcard
          GestureDetector(
            onTap: _flipCard,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: _isFlipped ? Colors.blue[50] : Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isFlipped ? currentCard.back : currentCard.front,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isFlipped) ...[
                        SizedBox(height: 20),
                        TextField(
                          onChanged: (value) => _userAnswer = value,
                          onSubmitted: (_) => _checkAnswer(),
                          decoration: InputDecoration(
                            labelText: 'Your answer',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          child: Text('Submit Answer'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Correct: ${cardStats.totalCorrect}'),
                Text('Wrong: ${cardStats.totalWrong}'),
              ],
            ),
          ),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => _recordAnswer(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Wrong'),
              ),
              ElevatedButton(
                onPressed: () => _recordAnswer(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Correct'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCardsMessage() {
    return Expanded(
      child: Center(
        child: Text(
          'No cards in this category yet.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add New Card',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _frontController,
          decoration: InputDecoration(
            labelText: 'Front side (question)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _backController,
          decoration: InputDecoration(
            labelText: 'Back side (answer)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addCard,
          child: Text('Add Card'),
        ),
      ],
    );
  }
}

// Data Models
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
}

class Flashcard {
  final int id;
  final int categoryId;
  final String front;
  final String back;

  Flashcard({
    required this.id,
    required this.categoryId,
    required this.front,
    required this.back,
  });
}

class CardStats {
  final int totalCorrect;
  final int totalWrong;

  CardStats({
    required this.totalCorrect,
    required this.totalWrong,
  });
}