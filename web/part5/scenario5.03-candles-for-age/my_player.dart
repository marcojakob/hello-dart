import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
  }

  /// Puts [count] stars in a row.
  putStars(int count) {
  }

  /// Makes a number of [steps] in the current direction.
  multiMove(int steps) {
  }

  /// Turns around by 180 degrees.
  turnAround() {
  }
}


main() {
  createWorld('scenario.txt', MyPlayer());
}
