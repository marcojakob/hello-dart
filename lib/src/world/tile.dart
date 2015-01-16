part of hello_dart;

/// A background tile.
class Tile {

  /// The horizontal position.
  int x;

  /// The vertical position.
  int y;

  /// The image name of the tile.
  String get imageName => 'field';

  Tile(this.x, this.y);
}