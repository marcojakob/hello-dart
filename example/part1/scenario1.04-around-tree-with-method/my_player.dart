import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    move();
    goAroundTree();
  }

  goAroundTree() {

  }
}


main() {
  createWorld('scenario.txt', new MyPlayer());
}
