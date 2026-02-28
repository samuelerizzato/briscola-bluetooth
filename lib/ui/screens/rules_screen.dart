import 'dart:convert';
import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString('assets/rules.json'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData) {
            return Text('Could not load rules');
          }

          Map<String, dynamic> rules = jsonDecode(snapshot.data!);
          Map<String, dynamic> ranks = rules['ranks'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16.0,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      buildDescription(Text(rules['goal'])),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game structure',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      buildDescription(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(rules['total']), Text(rules['card'])],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to play',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      buildDescription(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5.0,
                          children: [
                            Text(rules['start']),
                            Text(rules['turnSystem']),
                            Text(rules['turnEnd']),
                            Text(rules['tricks']),
                            Text(rules['decide']),
                            Text(rules['end']),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text('Cards', style: Theme.of(context).textTheme.titleLarge),
                  Text('Suits', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildSuitItem('assets/images/sword.png', 'Sword'),
                      buildSuitItem('assets/images/coin.png', 'Coin'),
                      buildSuitItem('assets/images/cup.png', 'Cup'),
                      buildSuitItem('assets/images/baton.png', 'Baton'),
                    ],
                  ),
                  Text('Ranks', style: Theme.of(context).textTheme.titleMedium),
                  buildDescription(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ranks.entries
                          .map((entry) => buildRankItem(entry.key, entry.value))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSuitItem(String assetName, String name) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(0x55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Image(image: AssetImage(assetName)),
          Text(name),
        ],
      ),
    );
  }

  Widget buildDescription(Widget child) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(0x55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget buildRankItem(String name, String description) {
    return Row(
      spacing: 10.0,
      children: [
        Expanded(child: Text(name)),
        Text(description),
      ],
    );
  }
}
