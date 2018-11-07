part of hello_dart;

/// A tree is a barrier for the player. The player can neither move through
/// nor push trees.
class Tree extends Actor {
  /// Constructor.
  Tree(World world, int x, int y) : super(world, x, y);

  @override
  BitmapData get image {
    return world.resourceManager.getBitmapData('tree');
  }

  @override
  int get zIndex => 3;
}
