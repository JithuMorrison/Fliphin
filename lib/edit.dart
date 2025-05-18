// edit_category_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // Assuming Category model is here
import 'dbhelper.dart';

class EditCategoryScreen extends StatefulWidget {
  final Category category;

  const EditCategoryScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController iconController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category.name);
    descriptionController = TextEditingController(text: widget.category.description);
    iconController = TextEditingController(text: widget.category.icon);
  }

  void _saveCategory() async {
    final updatedCategory = Category(
      id: widget.category.id,
      name: nameController.text,
      description: descriptionController.text,
      icon: iconController.text,
    );
    await DatabaseHelper.instance.updateCategory(updatedCategory);
    Navigator.pop(context, true); // Return true to indicate successful update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: iconController, decoration: InputDecoration(labelText: 'Icon')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
