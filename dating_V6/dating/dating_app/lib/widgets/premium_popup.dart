import 'package:flutter/material.dart';

class PremiumPopup extends StatelessWidget {
  final String feature;

  const PremiumPopup({Key? key, required this.feature}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Premium Feature'),
      content: Text('$feature is a premium feature. Upgrade to access it!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/premium');
          },
          child: Text('Upgrade Now'),
        ),
      ],
    );
  }
}
