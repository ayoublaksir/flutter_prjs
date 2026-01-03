import 'package:flutter/material.dart';

class CategoryServicesScreen extends StatelessWidget {
  final Map<String, dynamic> category;

  const CategoryServicesScreen({Key? key, required this.category})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category['name'] ?? 'Category Services')),
      body: Center(
        child: Text(
          'Services for ${category['name'] ?? 'this category'} coming soon',
        ),
      ),
    );
  }
}
