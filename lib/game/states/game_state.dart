import 'package:briscola/game/states/state_machine.dart';

abstract interface class GameState {
  void enter(StateMachine stateMachine);
  void exit(StateMachine stateMachine);
}