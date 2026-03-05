import 'package:briscola/game/commands/move_command.dart';

class CommandInvoker {
  CommandInvoker._();

  static void execute(MoveCommand command) {
    command.execute();
  }
}