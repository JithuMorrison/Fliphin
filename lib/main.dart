import 'dart:math';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'cardcategory.dart';
import 'dbhelper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Flashcards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardPage(),
        '/addCategory': (context) => AddCategoryPage(),
        '/categoryCards': (context) => CategoryCardsPage(),
        '/playCards': (context) => PlayCardsPage(),
      },
    );
  }
}

class Category {
  final int? id;
  final String name;
  final String description;
  final String icon;

  Category({
    this.id,
    required this.name,
    this.description = '',
    this.icon = '📚',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }

  static Category fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
    );
  }
}

class Flashcard {
  final int? id;
  final int categoryId;
  final String front;
  final String back;

  Flashcard({
    this.id,
    required this.categoryId,
    required this.front,
    required this.back,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'front': front,
      'back': back,
    };
  }

  static Flashcard fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      categoryId: map['category_id'],
      front: map['front'],
      back: map['back'],
    );
  }
}

class CardStat {
  final int? id;
  final int cardId;
  final int categoryId;
  final DateTime date;
  final bool isCorrect;

  CardStat({
    this.id,
    required this.cardId,
    required this.categoryId,
    required this.date,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'category_id': categoryId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'correct': isCorrect ? 1 : 0,
      'wrong': isCorrect ? 0 : 1,
    };
  }

  static CardStat fromMap(Map<String, dynamic> map) {
    return CardStat(
      id: map['id'],
      cardId: map['card_id'],
      categoryId: map['category_id'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      isCorrect: map['correct'] == 1,
    );
  }
}

// Pages
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = DatabaseHelper.instance.getAllCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = DatabaseHelper.instance.getAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshCategories,
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories yet. Add one!'));
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return _CategoryCard(
                category: category,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/playCards',
                  arguments: category,
                ),
                onAddCards: () => Navigator.pushNamed(
                  context,
                  '/categoryCards',
                  arguments: category,
                ),
                ondelete: _refreshCategories,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, '/addCategory');
          _refreshCategories();
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onAddCards;
  final VoidCallback ondelete;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onAddCards,
    required this.ondelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                category.icon,
                style: TextStyle(fontSize: 32),
                ),
                SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  category.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                FutureBuilder<Map<String, dynamic>>(
                  future: DatabaseHelper.instance.getCategoryStats(category.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox();
                    }
                    return Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        Text(' ${snapshot.data?['total_correct'] ?? 0}'),
                        SizedBox(width: 8),
                        Icon(Icons.close, color: Colors.red, size: 16),
                        Text(' ${snapshot.data?['total_wrong'] ?? 0}'),
                      ],
                    );
                  },
                ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete Category'),
                          content: Text('Are you sure you want to delete this category and all its cards?'),
                          actions: [
                            TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
                            TextButton(child: Text('Delete'), onPressed: () => Navigator.pop(context, true)),
                          ],
                        ),
                      );

                      if (confirm ?? false) {
                        await DatabaseHelper.instance.deleteCategory(category.id!);
                        ondelete();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: onAddCards,
                  ),
                  IconButton(onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryCardListPage(category: category),
                      ),
                    );
                  }, icon: Icon(Icons.remove_red_eye)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCategoryPage extends StatefulWidget {
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIcon = '📚';

  final List<String> icons = ['📚', '🧠', '🔬', '📖', '🧪', '🌍', '📝', '🧮'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        name: _nameController.text,
        description: _descController.text,
        icon: _selectedIcon,
      );
      await DatabaseHelper.instance.createCategory(category);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Category'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              Text('Select Icon', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) {
                  return ChoiceChip(
                    label: Text(icon, style: TextStyle(fontSize: 24)),
                    selected: _selectedIcon == icon,
                    onSelected: (selected) {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCategory,
                child: Text('Save Category'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCardsPage extends StatefulWidget {
  @override
  _CategoryCardsPageState createState() => _CategoryCardsPageState();
}

class _CategoryCardsPageState extends State<CategoryCardsPage> {
  late Category category;
  late Future<List<Flashcard>> _cardsFuture;
  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Category;
      setState(() {
        category = args;
        _cardsFuture = DatabaseHelper.instance.getCardsByCategory(category.id!);
      });
    });
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = DatabaseHelper.instance.getCardsByCategory(category.id!);
    });
  }

  Future<void> _addCard() async {
    if (_frontController.text.isEmpty || _backController.text.isEmpty) return;

    final card = Flashcard(
      categoryId: category.id!,
      front: _frontController.text,
      back: _backController.text,
    );
    await DatabaseHelper.instance.createCard(card);
    _frontController.clear();
    _backController.clear();
    _refreshCards();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cards in ${category.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _frontController,
                  decoration: InputDecoration(
                    labelText: 'Front (Question)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _backController,
                  decoration: InputDecoration(
                    labelText: 'Back (Answer)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addCard,
                  child: Text('Add Card'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Flashcard>>(
              future: _cardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading cards'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No cards yet'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final card = snapshot.data![index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.front,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              card.back,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PlayCardsPage extends StatefulWidget {
  @override
  _PlayCardsPageState createState() => _PlayCardsPageState();
}

class _PlayCardsPageState extends State<PlayCardsPage> with SingleTickerProviderStateMixin {
  late Category category;
  late Future<List<Flashcard>> _cardsFuture;
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _answerChecked = false;
  bool _isCorrect = false;
  final _answerController = TextEditingController();
  int _correctCount = 0;
  int _wrongCount = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  final Duration _flipDuration = Duration(milliseconds: 500);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is Category) {
      category = args;
      _cardsFuture = DatabaseHelper.instance.getCardsByCategory(category.id!);
    } else {
      throw Exception('Category not passed to PlayCardsPage');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _flipDuration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Animation completed
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _loadStats();
        _loadCards();
      });
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getCategoryStats(category.id!);
    setState(() {
      _correctCount = stats['total_correct'] ?? 0;
      _wrongCount = stats['total_wrong'] ?? 0;
    });
  }

  Future<void> _loadCards() async {
    _cards = await DatabaseHelper.instance.getCardsByCategory(category.id!);
    if (_cards.isNotEmpty) {
      setState(() {
        _currentIndex = 0;
        _isFlipped = false;
        _answerChecked = false;
        _answerController.clear();
      });
    }
  }

  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final correctAnswer = _cards[_currentIndex].back.toLowerCase();
    final userAnswer = _answerController.text.toLowerCase();

    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _answerChecked = true;

      if (_isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    _recordStat(_isCorrect);
  }

  Future<void> _recordStat(bool isCorrect) async {
    final stat = CardStat(
      cardId: _cards[_currentIndex].id!,
      categoryId: category.id!,
      date: DateTime.now(),
      isCorrect: isCorrect,
    );
    await DatabaseHelper.instance.createStat(stat);
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _answerChecked = false;
        _answerController.clear();
        _controller.reset();
      });
    } else {
      // End of cards
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Finished!'),
          content: Text('You\'ve gone through all cards in this category.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 0;
                  _isFlipped = false;
                  _answerChecked = false;
                  _answerController.clear();
                  _controller.reset();
                });
              },
              child: Text('Start Over'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleCard() {
    if (_controller.isAnimating) return;

    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }

    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Widget _buildFrontCard(Flashcard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.front,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAnswer,
              child: Text('Check Answer', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Flashcard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.back,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (_answerChecked)
              Text(
                _isCorrect ? '✅ Correct!' : '❌ Incorrect',
                style: TextStyle(
                  fontSize: 24,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextCard,
              child: Text('Next Card', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipCard(Flashcard card) {
    return GestureDetector(
      onTap: _answerChecked ? _toggleCard : null,
      child: AnimatedSwitcher(
        duration: _flipDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isHalfway = animation.value <= 0.5;
              final value = isHalfway ? pi - rotateAnim.value : rotateAnim.value;
              return Transform(
                transform: Matrix4.rotationY(value),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _isFlipped
            ? _buildBackCard(card)
            : _buildFrontCard(card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play: ${category.name}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Flashcard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading cards'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No cards in this category yet.'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/categoryCards',
                      arguments: category,
                    ),
                    child: Text('Add Cards'),
                  ),
                ],
              ),
            );
          }

          _cards = snapshot.data!;
          final currentCard = _cards[_currentIndex];

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCounter(Icons.check, 'Correct', _correctCount, Colors.green),
                    _buildStatCounter(Icons.close, 'Wrong', _wrongCount, Colors.red),
                    _buildStatCounter(Icons.library_books, 'Progress', _currentIndex + 1, Colors.blue, total: _cards.length),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      AspectRatio(
                        aspectRatio: 0.8,
                        child: _buildFlipCard(currentCard),
                      ),
                      SizedBox(height: 30),
                      if (_answerChecked && !_isFlipped && !_isCorrect)
                        Text(
                          'Correct answer: ${currentCard.back}',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _answerChecked
          ? FloatingActionButton(
        child: Icon(_isFlipped ? Icons.visibility_off : Icons.visibility),
        onPressed: _toggleCard,
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }

  Widget _buildStatCounter(IconData icon, String label, int value, Color color, {int? total}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 4),
            Text(
              '$value${total != null ? '/$total' : ''}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}