import 'package:flutter/material.dart';

class Dialogs {
  static Future<bool?> showBackDialog(
    BuildContext context,
    void Function() onConfirm,
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
            Navigator.pop(context, false);
          },
          child: const Text('Nevermind'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          onPressed: onConfirm,
          child: const Text('Leave'),
        ),
      ],
    ),
  );
}
