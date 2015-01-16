part of hello_dart;

/// A tree is a barrier for the player. The player can neither move through
/// nor push trees.
class Tree extends Actor {

  /// Constructor.
  Tree(World world, int x, int y) : super(world, x, y);

  @override
  String get imageName => 'tree';
}
