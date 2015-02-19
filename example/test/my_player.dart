import 'package:hello_dart/hello_dart.dart';

/// Your player.
class MyPlayer extends Player {

  /// Your program.
  start() {
    var i;
    i = 0;

    while (i < 5) {
      putStar();
      move();

      i = i + 1;
    }
  }
}


main() {
  character = 'boy';
  backgroundColorTop = '#fff';
  createWorld('scenario.txt', new MyPlayer());
}
