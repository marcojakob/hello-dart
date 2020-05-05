import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
  }
}


main() {
  createWorld('scenario-a.txt', MyPlayer());
}
