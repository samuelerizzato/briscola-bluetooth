import 'package:briscola/ui/screens/game_screen.dart';
import 'package:briscola/ui/screens/peripheral_lobby_screen.dart';
import 'package:briscola/ui/screens/central_lobby_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Briscola',
                    style: const TextStyle(fontSize: 50.0),
                  ),
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Icon(Icons.bluetooth, size: 50.0),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              spacing: 40.0,
              children: [
                buildButton('play locally', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(),
                      settings: RouteSettings(name: '/GameScreen'),
                    ),
                  );
                }),
                buildButton('enter game', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CentralLobbyScreen(),
                      settings: RouteSettings(name: '/CentralLobby'),
                    ),
                  );
                }),
                buildButton('host game', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PeripheralLobbyScreen(),
                      settings: RouteSettings(name: '/PeripheralLobby'),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    ),
    onPressed: onPressed,
    child: Text(text.toUpperCase()),
  );
}
