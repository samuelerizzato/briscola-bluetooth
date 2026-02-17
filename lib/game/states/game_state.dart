import 'package:briscola/game/states/state_machine.dart';

abstract interface class GameState {
  Future<void> enter(StateMachine stateMachine);
  Future<void> exit(StateMachine stateMachine);
}