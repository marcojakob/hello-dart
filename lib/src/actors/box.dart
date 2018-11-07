part of hello_dart;

/// Boxes can be pushed by the player if there is nothing behind them.
class Box extends Actor {
  /// Constructor.
  Box(World world, int x, int y) : super(world, x, y);

  @override
  BitmapData get image {
    return world.resourceManager.getBitmapData('box');
  }

  @override
  int get zIndex => 2;

  /// Returns true if this box can be moved to the next field.
  bool canMove(Direction direction) {
    // 1. Must have a field in front.
    // 2. Must not have a tree or a box in front.
    return world.getFieldInFront(x, y, direction) != null &&
        !world
            .getActorsInFront(x, y, direction)
            .any((a) => a is Tree || a is Box);
  }
}
