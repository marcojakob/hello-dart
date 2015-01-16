part of hello_dart;

/// This is the superclass for all Players.
///
/// Your program should be written in a subclass of this class.
abstract class Player extends Actor {

  /// Constructor.
  Player() : super(null, -1, -1);

  /// The start method where you can write your program.
  void start();

  /// The player makes a step in the current direction.
  void move() {
    // Check for a tree.
    if (treeFront()) {
      world.queueAction((spd) {
        throw new PlayerException(messages.cantMoveBecauseOfTree());
      });
      _stop();
    }

    // Check for a box.
    Box box = world.getActorsInFront(x, y, direction)
        .firstWhere((Actor a) => a is Box, orElse: () => null);

    if (box != null) {
      // Check if the box can be pushed to the next field.
      if (!world.getActorsInFront(x, y, direction, 2)
          .any((Actor a) => a is Tree || a is Box)) {

        Point boxStartPoint = new Point(box.x, box.y);
        Point playerStartPoint = new Point(x, y);

        // Push the box and move the player.
        box._move(direction);
        _move(direction);

        Point boxEndPoint = new Point(box.x, box.y);
        Point playerEndPoint = new Point(x, y);

        // Copy the current box image name and the player's direction.
        String boxImageName = box.imageName;
        int playerDirection = direction;

        world.queueAction((spd) {
          AnimationGroup animGroup = new AnimationGroup();
          animGroup.add(box._bitmap.moveAnimation(boxStartPoint, boxEndPoint,
                                                  playerDirection, spd));
          animGroup.add(box._bitmap.delayedUpdateImage(boxImageName, spd));
          animGroup.add(_bitmap.moveAnimation(playerStartPoint, playerEndPoint,
                                              playerDirection, spd));

          world.juggler.add(animGroup);
        });

      } else {
        // Could not push the box.
        world.queueAction((spd) {
          throw new PlayerException(messages.cantMoveBecauseOfBox());
        });
        _stop();
      }
    } else {
      // Nothing in the way, the player can move.
      Point playerStartPoint = new Point(x, y);
      _move(direction);
      Point playerEndPoint = new Point(x, y);
      int playerDirection = direction;

      world.queueAction((spd) {
        world.juggler.add(_bitmap.moveAnimation(playerStartPoint, playerEndPoint,
                                                playerDirection, spd));
      });
    }
  }

  /// The player turns left by 90 degrees.
  void turnLeft() {
    direction = (direction - 90) % 360;

    world.queueAction((spd) {
      Animatable anim = _bitmap.turnByAnimation(-math.PI / 2, spd);
      world.juggler.add(anim);
    });
  }

  /// The player turns right by 90 degrees.
  void turnRight() {
    direction = (direction + 90) % 360;

    world.queueAction((spd) {
      world.juggler.add(_bitmap.turnByAnimation(math.PI / 2, spd));
    });
  }

  /// The player puts down a star.
  void putStar() {
    if (!onStar()) {
      Star star = new Star(world, x, y);
      world.actors.add(star);

      world.queueAction((spd) {
        star._addToWorld();
      });
    } else {
      world.queueAction((spd) {
        throw new PlayerException(messages.cantPutStar());
      });
      _stop();
    }
  }

  /// The player picks up a star.
  void removeStar() {
    Star star = world.getActorsAt(x, y).firstWhere((Actor a) => a is Star,
        orElse: () => null);

    if (star != null) {
      world.actors.remove(star);

      world.queueAction((spd) {
        star._removeFromWorld();
      });
    } else {
      world.queueAction((spd) {
        throw new PlayerException(messages.cantRemoveStar());
      });
      _stop();
    }
  }

  /// The player checks if he stands on a star.
  bool onStar() {
    return world.getActorsAt(x, y).any((Actor a) => a is Star);
  }

  /// The player checks if there is a tree in front of him.
  bool treeFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his left side.
  bool treeLeft() {
    return world.getActorsInFront(x, y, (direction - 90) % 360).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a tree on his right side.
  bool treeRight() {
    return world.getActorsInFront(x, y, (direction + 90) % 360).any((Actor a) => a is Tree);
  }

  /// The player checks if there is a box in front of him.
  bool boxFront() {
    return world.getActorsInFront(x, y, direction).any((Actor a) => a is Box);
  }

  @override
  String get imageName => character;

  /// Stops the execution.
  void _stop() {
    // We throw an exception here because it is the only way to immediately
    // leave an executing method.
    throw new StopException();
  }
}
