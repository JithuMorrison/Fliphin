import 'package:flutter/material.dart';
import 'dbhelper.dart';
import 'main.dart'; // For Flashcard model

class EditFlashcardScreen extends StatefulWidget {
  final Flashcard flashcard;

  const EditFlashcardScreen({Key? key, required this.flashcard}) : super(key: key);

  @override
  _EditFlashcardScreenState createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  late TextEditingController frontController;
  late TextEditingController backController;

  @override
  void initState() {
    super.initState();
    frontController = TextEditingController(text: widget.flashcard.front);
    backController = TextEditingController(text: widget.flashcard.back);
  }

  Future<void> _saveFlashcard() async {
    final updatedCard = Flashcard(
      id: widget.flashcard.id,
      categoryId: widget.flashcard.categoryId,
      front: frontController.text,
      back: backController.text,
    );

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cards',
      updatedCard.toMap(),
      where: 'id = ?',
      whereArgs: [updatedCard.id],
    );

    Navigator.pop(context, true); // Return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Flashcard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: frontController, decoration: InputDecoration(labelText: 'Front')),
            TextField(controller: backController, decoration: InputDecoration(labelText: 'Back')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveFlashcard,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
