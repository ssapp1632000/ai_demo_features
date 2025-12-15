import 'package:flutter/material.dart';
import '../widgets/home_body.dart';

class TextEnhancementPage extends StatelessWidget {
  const TextEnhancementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Text Enhancement",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepOrangeAccent,
              ),
              child: Text(
                'AI Demo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pop(context); // Go back to home
              },
            ),
            ListTile(
              leading: Icon(Icons.text_fields),
              title: Text('Text Enhancement'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
          ],
        ),
      ),
      body: HomeBody(
        onSubmit: (text) {
          print("Text Submitted: $text");
        },
      ),
    );
  }
}
