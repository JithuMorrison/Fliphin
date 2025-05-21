import 'dbhelper.dart';
import 'edit.dart';
import 'editcard.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class CategoryCardListPage extends StatefulWidget {
  final Category category;

  const CategoryCardListPage({required this.category});

  @override
  _CategoryCardListPageState createState() => _CategoryCardListPageState();
}

class _CategoryCardListPageState extends State<CategoryCardListPage> {
  late Future<List<Flashcard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    _cardsFuture = DatabaseHelper.instance.getCardsByCategory(widget.category.id!);
  }

  Future<void> _deleteCard(int cardId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
    setState(() {
      _loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.name} Cards')),
      body: FutureBuilder<List<Flashcard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;
          if (cards.isEmpty) return Center(child: Text('No cards found.'));

          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                child: ListTile(
                  title: Text(card.front),
                  subtitle: Text(card.back),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditFlashcardScreen(flashcard: card),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              _loadCards(); // Refresh the card list after editing
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Delete Card'),
                              content: Text('Are you sure you want to delete this card?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm ?? false) _deleteCard(card.id!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}