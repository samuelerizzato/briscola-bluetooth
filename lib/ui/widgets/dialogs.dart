import 'package:flutter/material.dart';

class Dialogs {
  static Future<bool?> showBackDialog(
    BuildContext context,
    Future<bool> Function() onConfirm,
  ) => showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Are you sure?'),
      content: const Text('If you leave you\'re going to lose the game'),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Nevermind'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          onPressed: () async {
            bool shouldNavigate = await onConfirm();
            if (context.mounted) {
              Navigator.of(context).pop(shouldNavigate);
            }
          },
          child: const Text('Leave'),
        ),
      ],
    ),
  );
}
