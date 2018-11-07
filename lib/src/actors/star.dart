part of hello_dart;

/// A star can be put and removed by the player.
class Star extends Actor {
  /// Constructor.
  Star(World world, int x, int y) : super(world, x, y);

  @override
  BitmapData get image {
    return world.resourceManager.getBitmapData('star');
  }

  @override
  int get zIndex => 1;
}
