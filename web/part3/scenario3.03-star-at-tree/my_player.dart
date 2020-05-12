import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    while (canMove()) {
      
    }
  }
}


main() {
  createWorld('scenario.txt', MyPlayer());
}
