import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    while (canMove()) {
if (treeLeft() || treeRight()) {
        putStar();
      }
      move();
    }
  }
}


main() {
  createWorld('scenario.txt', MyPlayer());
}
