import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flashcards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        icon TEXT
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
        category_id INTEGER,
        date TEXT,
        correct INTEGER,
        wrong INTEGER,
        FOREIGN KEY (card_id) REFERENCES cards (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  // Category operations
  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // Card operations
  Future<int> createCard(Flashcard card) async {
    final db = await instance.database;
    return await db.insert('cards', card.toMap());
  }

  Future<List<Flashcard>> getCardsByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return result.map((json) => Flashcard.fromMap(json)).toList();
  }

  // Stat operations
  Future<int> createStat(CardStat stat) async {
    final db = await instance.database;
    return await db.insert('stats', stat.toMap());
  }

  Future<List<CardStat>> getStatsByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'stats',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return result.map((json) => CardStat.fromMap(json)).toList();
  }

  Future<Map<String, dynamic>> getCategoryStats(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(correct) as total_correct,
        SUM(wrong) as total_wrong
      FROM stats
      WHERE category_id = ?
    ''', [categoryId]);

    return {
      'total_correct': result.first['total_correct'] ?? 0,
      'total_wrong': result.first['total_wrong'] ?? 0,
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}