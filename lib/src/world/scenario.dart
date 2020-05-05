part of hello_dart;

/// A [Scenario] contains information about the positions of the actors in the
/// world.
///
/// The actors are described with the following signs:
/// * Player: @
/// * Tree: %
/// * Star: .
/// * Box: $
/// * Box on star: *
/// * Player on star: +
///
/// The background:
/// * Empty: a space
/// * Border or holes: #
///
/// Note: The border must form a polygon with the actors inside.
class Scenario {
  static const String undefined = '?';

  static const String player = '@';
  static const String tree = '%';
  static const String star = '.';
  static const String box =
      r'$'; // r means raw String (treats dollar sign as a normal String)
  static const String boxStar = '*';
  static const String playerStar = '+';
  static const String empty = ' ';
  static const String borderOrHole = '#';

  /// The title of the [Scenario].
  final String title;

  /// Actor and background positions.
  ///
  /// Each list entry is a line (y-position) and the position of the character
  /// in the String is the column (x-position).
  ///
  /// Note: Each line must have the same length.
  final List<String> positions;

  /// The width in number of cells (includes outer border tiles).
  int get _width => positions[0].length;

  /// The world in number of rows (includes outer border tiles).
  int get _height => positions.length;

  /// Creates a [Scenario] with specified [title] and [positions] of actors
  /// and background tiles.
  Scenario({this.title = 'untitled', this.positions = const ['@']}) {
    // Validate scenario positions.
    if (positions.isEmpty || positions[0].isEmpty) {
      throw ScenarioException(messages.scenarioInvalid());
    }
  }

  /// Builds a list of [Actor]s according to this [Scenario].
  void build(World world) {
    _buildActors(world);
    _buildBackgroundTiles(world);

    // Subtract one from x and y because of the additional border in the scenario.
    world.actors.forEach((actor) {
      actor.x--;
      actor.y--;
    });

    world.fields.forEach((tile) {
      tile.x--;
      tile.y--;
    });
  }

  /// Builds the actors and adds them to [world].
  void _buildActors(World world) {
    // Clear the world's actors.
    world.actors = [];

    bool playerAdded = false;

    for (int y = 0; y < positions.length; y++) {
      for (int x = 0; x < positions[y].length; x++) {
        switch (positions[y][x]) {
          case Scenario.player:
            // Only add first occurrence of the player.
            if (!playerAdded) {
              world.player
                ..x = x
                ..y = y
                ..direction = Direction.right;
              world.actors.add(world.player);
              playerAdded = true;
            }
            break;
          case Scenario.tree:
            world.actors.add(Tree(world, x, y));
            break;
          case Scenario.star:
            world.actors.add(Star(world, x, y));
            break;
          case Scenario.box:
            world.actors.add(Box(world, x, y));
            break;
          case Scenario.boxStar:
            world.actors.add(Box(world, x, y));
            world.actors.add(Star(world, x, y));
            break;
          case Scenario.playerStar:
            // Only add first occurrence of the player.
            if (!playerAdded) {
              world.player
                ..x = x
                ..y = y
                ..direction = Direction.right;
              world.actors.add(world.player);
              playerAdded = true;
            }
            world.actors.add(Star(world, x, y));
            break;
        }
      }
    }
  }

  /// Builds the background tiles and adds them to [world].
  void _buildBackgroundTiles(World world) {
    // Reset the worlds tiles.
    world.fields = [];

    // 1. Calculate outline.
    List<String> outline = _findOutline();

    // 2. Create tiles.

    // # How we determine if we're inside or outside of the world
    //
    // The border forms a polygon. Inside the polygon, the empty fields
    // have a background tile while outside the polygon the empty fields are
    // empty. To determine whether a point is inside or outside of a polygon
    // we use an algorithm based on the Jordan curve theorem. It uses rays from
    // left to right and counts the number of intersections with the polygon.
    // A good explanation is here:
    // http://muongames.com/2013/07/point-in-a-polygon-in-as3-theory-and-code/

    for (int y = 0; y < outline.length; y++) {
      int intersections = 0;

      bool horizontally = false;
      bool
          horizontallyFromUp; // True if we came from up to the horizontal line.

      for (int x = 0; x < outline[y].length; x++) {
        if (outline[y][x] == Scenario.borderOrHole) {
          // We must be careful when moving on horizontal lines that we don't
          // count them as intersections when we're only moving along an outer
          // border and not actually intersecting.
          //
          // * If the outline was moving up, then horizontally and down again,
          //   there was no intersection. Same for down and up.
          // * If it was moving up, then horizontally and then up again,
          //   there was an intersection. Same for down and down.

          // Peek ahead to see if we're going horizontally.
          if (x + 1 < _width && outline[y][x + 1] == Scenario.borderOrHole) {
            // We're going horizontally.
            if (!horizontally) {
              // We're at the start of going horizontally, save the direction
              // we were coming from.
              horizontally = true;
              if (y > 0 && outline[y - 1][x] == Scenario.borderOrHole) {
                horizontallyFromUp = false;
              } else {
                horizontallyFromUp = true;
              }
            }
          } else {
            if (horizontally) {
              // We're at the end of a horizontal line.
              // Peak ahead if we are going up or down.
              if (y > 0 && outline[y - 1][x] == Scenario.borderOrHole) {
                // We are going up. If we also came from up, we have an intersection!
                if (horizontallyFromUp) {
                  intersections++;
                }
              } else {
                // We are going down. If we also came from down, we have an intersection!
                if (!horizontallyFromUp) {
                  intersections++;
                }
              }

              horizontally = false;
              horizontallyFromUp = null;
            } else {
              // Not going horizontally.
              intersections++;
            }
          }
        } else if (intersections % 2 == 1) {
          // Uneven intersections means we are inside the polygon.

          // Add the tile unless there is a hole inside the polygon.
          if (positions[y][x] != Scenario.borderOrHole) {
            world.fields.add(Field(world, x, y));
          }
        }
      }
    }
  }

  /// Returns a list with just the outline of all non-empty characters.
  List<String> _findOutline() {
    if (positions.isEmpty) return List();

    // Fill result list with empty Strings.
    List<List<String>> outlineLines =
        List.generate(_height, (_) => List.filled(_width, Scenario.empty));

    // 1. Find top-left point.
    Point<int> startPoint = _topLeft();

    // 2. Find all the points until we are at the start point again.
    Point<int> currentPoint = startPoint;
    String lastDirection = 'U';

    do {
      // Add the current point to the result as direction letter.
      outlineLines[currentPoint.y][currentPoint.x] = Scenario.borderOrHole;

      // Find the next point.
      _Pair<Point<int>, String> pair;
      switch (lastDirection) {
        case 'U': // up
          pair = _findOutlineLeft(currentPoint);
          break;
        case 'R': // right
          pair = _findOutlineUp(currentPoint);
          break;
        case 'D': // down
          pair = _findOutlineRight(currentPoint);
          break;
        case 'L': // left
          pair = _findOutlineDown(currentPoint);
          break;
      }

      if (pair == null) {
        // No valid outline found.
        throw ScenarioException(messages.scenarioInvalid());
      }

      currentPoint = pair.first;
      lastDirection = pair.last;
    } while (currentPoint != startPoint);

    return outlineLines.map((line) => line.join()).toList(growable: false);
  }

  /// Finds the top left border field in [positions].
  Point<int> _topLeft() {
    for (int y = 0; y < positions.length; y++) {
      for (int x = 0; x < positions[y].length; x++) {
        if (positions[y][x] == Scenario.borderOrHole) {
          return Point(x, y);
        }
      }
    }

    // Nothing found.
    throw ScenarioException(messages.scenarioInvalid());
  }

  /// Rotates through all four directions, starting with UP to check if there
  /// is a [Scenario.borderOrHole] field in any of those directions.
  ///
  /// Returns the point that was found along with the direction.
  ///
  /// The [directionCountdown] is used to count how many directions were tested.
  /// If it reaches 0 and no point has been found, null is returned.
  _Pair<Point<int>, String> _findOutlineUp(Point<int> p,
      {int directionCountdown = 3}) {
    if (directionCountdown > 0) {
      if (p.y > 0 && positions[p.y - 1][p.x] == Scenario.borderOrHole) {
        return _Pair(Point(p.x, p.y - 1), 'U');
      } else {
        return _findOutlineRight(p, directionCountdown: directionCountdown - 1);
      }
    }
    return null;
  }

  /// Rotates through all four directions, starting with RIGHT to check if there
  /// is a [Scenario.borderOrHole] field in any of those directions.
  ///
  /// Returns the point that was found along with the direction.
  ///
  /// The [directionCountdown] is used to count how many directions were tested.
  /// If it reaches 0 and no point has been found, null is returned.
  _Pair<Point<int>, String> _findOutlineRight(Point<int> p,
      {int directionCountdown = 3}) {
    if (directionCountdown > 0) {
      if (p.x + 1 < _width &&
          positions[p.y][p.x + 1] == Scenario.borderOrHole) {
        return _Pair(Point(p.x + 1, p.y), 'R');
      } else {
        return _findOutlineDown(p, directionCountdown: directionCountdown - 1);
      }
    }
    return null;
  }

  /// Rotates through all four directions, starting with DOWN to check if there
  /// is a [Scenario.borderOrHole] field in any of those directions.
  ///
  /// Returns the point that was found along with the direction.
  ///
  /// The [directionCountdown] is used to count how many directions were tested.
  /// If it reaches 0 and no point has been found, null is returned.
  _Pair<Point<int>, String> _findOutlineDown(Point<int> p,
      {int directionCountdown = 3}) {
    if (directionCountdown > 0) {
      if (p.y + 1 < _height &&
          positions[p.y + 1][p.x] == Scenario.borderOrHole) {
        return _Pair(Point(p.x, p.y + 1), 'D');
      } else {
        return _findOutlineLeft(p, directionCountdown: directionCountdown - 1);
      }
    }
    return null;
  }

  /// Rotates through all four directions, starting with LEFT to check if there
  /// is a [Scenario.borderOrHole] field in any of those directions.
  ///
  /// Returns the point that was found along with the direction.
  ///
  /// The [directionCountdown] is used to count how many directions were tested.
  /// If it reaches 0 and no point has been found, null is returned.
  _Pair<Point<int>, String> _findOutlineLeft(Point<int> p,
      {int directionCountdown = 3}) {
    if (directionCountdown > 0) {
      if (p.x > 0 && positions[p.y][p.x - 1] == Scenario.borderOrHole) {
        return _Pair(Point(p.x - 1, p.y), 'L');
      } else {
        return _findOutlineUp(p, directionCountdown: directionCountdown - 1);
      }
    }
    return null;
  }

  /// Parses the [scenarioString] and creates a [Scenario].
  ///
  /// The [scenarioString] must contain title, width, height, and actors
  /// entries.
  ///
  /// If the scenario couldn't be parsed, a [ScenarioException] is thrown.
  static Scenario parse(String scenarioString, String file) {
    var scanner = StringScanner(scenarioString);
    String title;
    if (scanner.scan(RegExp(r'(.*)\r?\n(.*)'))) {
      title = scanner.lastMatch[2];
    } else {
      throw ScenarioException(messages.scenarioInvalid());
    }

    String positions;
    if (scanner.scan(RegExp(r'\r?\n([\s\S]*)'))) {
      positions = scanner.lastMatch[1].trimRight();
    } else {
      throw ScenarioException(messages.scenarioInvalid());
    }

    List<String> positionLines = positions.split(RegExp(r'\r?\n'));

    int width =
        positionLines.fold(0, (val, line) => math.max(val, line.length));

    // Make all lines the same length.
    positionLines = positionLines
        .map((line) => line.padRight(width, Scenario.empty))
        .toList(growable: false);

    return Scenario(title: title, positions: positionLines);
  }
}

/// Util class for a pair of values.
class _Pair<E, F> {
  E first;
  F last;

  _Pair(this.first, this.last);
}
