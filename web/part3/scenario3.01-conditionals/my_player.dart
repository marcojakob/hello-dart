import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    while (canMove()) {
      // Put your conditional code here...
    }
  }
}


main() {
  createWorld('scenario.txt', MyPlayer());
}
