import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  int longestRow = 0;

  /// Your program.
  start() {
  }

}


main() {
  createWorld('scenario.txt', MyPlayer());
}
