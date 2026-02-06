import 'dart:async';
import 'dart:math';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/ui/screens/game_screen.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/screens/peripheral_lobby_screen.dart';
import 'package:briscola/ui/screens/central_lobby_screen.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/opponent_draw_state.dart';
import 'package:briscola/game/states/opponent_turn_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreen();
}

class _HomeScreen extends State<StatefulWidget> {
  StreamSubscription? _gameStateChangedSubscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Briscola',
                    style: TextStyle(
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Icon(
                        Icons.bluetooth,
                        size: 50.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              spacing: 40.0,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  onPressed: () {
                    final StateMachine stateMachine = StateMachine(
                      GameContext(PlayerType.local, (GameResult result) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                GameResultScreen(result: result),
                          ),
                        );
                      }),
                    );

                    final world = BriscolaWorld(
                      Random().nextInt(256),
                      stateMachine,
                    );

                    _gameStateChangedSubscription = stateMachine.stateChanged
                        .listen((state) {
                          if (state is OpponentTurnState) {
                            world.onRemotePlayCard(
                              stateMachine.context.opponentHand.cards.last,
                            );
                          } else if (state is OpponentDrawState) {
                            world.triggerOpponentDraw();
                          }
                        });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(world, () {
                          _gameStateChangedSubscription?.cancel();
                          stateMachine.dispose();
                        }),
                        settings: RouteSettings(name: '/GameScreen'),
                      ),
                    );
                  },
                  child: const Text('PLAY LOCALLY'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CentralLobbyScreen(),
                        settings: RouteSettings(name: '/CentralLobby'),
                      ),
                    );
                  },
                  child: const Text('ENTER GAME'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PeripheralLobbyScreen(),
                        settings: RouteSettings(name: '/PeripheralLobby'),
                      ),
                    );
                  },
                  child: const Text('HOST GAME'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
