part of hello_dart;

/// This class creates a world for the player and manages all other actors.
class World extends Sprite {

  /// The asset directory.
  static const String assetDir = 'packages/hello_dart';

  /// The width of one cell in pixels.
  static int cellWidth = 100;

  /// The height of one cell in pixels.
  static int cellHeight = 80;

  static int marginTop = 45;
  static int marginBottom = 46;

  /// The maximum number of calls to the player's action methods that are
  /// allowed.
  static const int maxActions = 10000;

  /// The scenario of this world.
  Scenario scenario;

  /// Instance of [Player] that contains the user's program.
  Player player;

  /// The duration between the execution of actions in milliseconds.
  Duration speed;

  /// A list of all actors except the player (stars, boxes and trees).
  List<Actor> actors;

  /// The background fields.
  List<Field> fields;

  int _widthInCells;

  /// The world width in number of cells.
  int get widthInCells {
    if (_widthInCells == null) {
      _initWidthAndHeight();
    }
    return _widthInCells;
  }

  int _heightInCells;

  /// The world height in number of rows.
  int get heightInCells {
    if (_heightInCells == null) {
      _initWidthAndHeight();
    }
    return _heightInCells;
  }

  /// Initializes the [widthInCells] and [heightInCells] depending on the
  /// [fields].
  void _initWidthAndHeight() {
    int maxX = 0;
    int maxY = 0;
    fields.forEach((field) {
      maxX = math.max(maxX, field.x);
      maxY = math.max(maxY, field.y);
    });

    _widthInCells = maxX + 1;
    _heightInCells = maxY + 1;
  }

  /// Returns the world's width in pixels (without margins).
  int get widthInPixels => widthInCells * cellWidth;

  /// Returns the world's height in pixels (without margins).
  int get heightInPixels => heightInCells * cellHeight;

  /// A Queue of player actions waiting to be executed.
  final Queue<PlayerAction> _actionQueue = new Queue();

  /// The subscription for enter frame events.
  StreamSubscription _enterFrameSub;

  /// The time when the next action may be executed, in milliseconds.
  num _nextActionTime = 0;

  // StageXL references.
  Stage stage;
  RenderLoop renderLoop;
  Juggler juggler;
  ResourceManager resourceManager;

  /// Creates a new World with the specified [player].
  ///
  /// [speed] defines the initial speed.
  World(this.player, this.speed) {
    // Pass a reference of this world to the player.
    player.world = this;
  }

  /// Initializes the world with the scenario.
  Future init(String scenarioFile) {
    // Load assets.
    return _loadAssets(scenarioFile).then((_) {
      // Init scenario.
      scenario = Scenario.parse(resourceManager.getTextFile('scenario'),
          scenarioFile);
      scenario.build(this);

      // Init the scenario title.
      _initTitle();

      // Init the speed slider.
      _initSpeedSlider();

      // Init the stage.
      _initStage();

      stage.addChild(this);

      // Draw the background cells.
      _drawBackground();

      // Add actors.
      actors.forEach((actor) => actor._bitmapAddToWorld());

      // Sort the background and actors.
      sortChildren(ZOrder.compare);

      // Execute the user's start()-method. This will fill the action queue.
      try {
        player.start();

      } on StopException {
        // Stop execution after all queued actions have been processed.
        _actionQueue.add((spd) {
          _enterFrameSub.cancel();
        });

      } on PlayerException catch (e) {
        // Stop execution after all queued actions have been processed, then
        // show the exception to the user.
        _actionQueue.add((spd) {
          _enterFrameSub.cancel();
          html.window.alert(e.toString());
        });
      }

      // Start listening to enter frame events of the browser's event loop.
      _enterFrameSub = onEnterFrame.listen((_) => _executeNextAction());
    });
  }

  /// Renders the current world state with [actors] and [player].
  ///
  /// Note: The rendering is not done immediately. The current world state is
  /// added to a queue where itmes are rendered with a fixed delay between them.
  void queueAction(PlayerAction action) {
    // Add the current world state at the end of the queue.
    _actionQueue.add(action);

    if (_actionQueue.length > maxActions) {
      // The maximum number of actions during one act()-call has been reached.
      throw new ActionOverflowException(messages.actionOverflowException());
    }
  }

  /// Returns the field at the specified location or null, if there is no field.
  Field getFieldAt(int x, int y) {
    return fields.firstWhere((field) => field.x == x && field.y == y,
        orElse: () => null);
  }


  /// Returns the field that is a number of [steps] away from [x], [y]
  /// in the specified [direction].
  Field getFieldInFront(int x, int y, Direction direction, [int steps = 1]) {
    Point p = World.getPointInFront(x, y, direction, steps);

    return getFieldAt(p.x, p.y);
  }

  /// Returns a list of actors at the specified location.
  List<Actor> getActorsAt(int x, int y) {
    return actors.where((Actor actor) => actor.x == x && actor.y == y)
        .toList(growable: false);
  }

  /// Returns a list of actors that are a number of [steps] away from [x], [y]
  /// in the specified [direction].
  List<Actor> getActorsInFront(int x, int y, Direction direction, [int steps = 1]) {
    Point p = World.getPointInFront(x, y, direction, steps);

    return getActorsAt(p.x, p.y);
  }

  /// Adds the [child] at the correct z-order position.
  void addChildAtZOrder(DisplayObjectZ child) {
    addChildAt(child, _getChildIndexForZOrder(child));
  }

  /// Recalculates the correct child index of [child] and updates it.
  void updateChildIndexZOrder(DisplayObjectZ child) {
    setChildIndex(child, math.min(_getChildIndexForZOrder(child), numChildren - 1));
  }

  /// Returns the correct child index where a child with [order] should be
  /// inserted.
  int _getChildIndexForZOrder(ZOrder order) {
    for (int i = 0; i < numChildren; i++) {
      if (ZOrder.compare(getChildAt(i), order) > 0) {
        return i;
      }
    }
    return numChildren;
  }

  /// Loads all assets.
  /// Assets are finished loading when the returned [Future] completes.
  Future<ResourceManager> _loadAssets(String scenarioFile) {
    Completer completer = new Completer();

    resourceManager = new ResourceManager();

    resourceManager
        ..addBitmapData('field', '${assetDir}/images/${background}.png')
        ..addBitmapData('star', '${assetDir}/images/star.png')
        ..addBitmapData('box', '${assetDir}/images/box.png')
        ..addBitmapData('tree', '${assetDir}/images/tree.png')
        ..addTextureAtlas('character', '${assetDir}/images/${character}.json',
            TextureAtlasFormat.JSONARRAY)
        ..addTextFile('scenario', scenarioFile);

    resourceManager.load().then((manager) {
      completer.complete(manager);
    }).catchError((error) {
      completer.completeError(
          new FileNotFoundException(messages.fileNotFoundException()));
    });

    return completer.future;
  }

  /// Initializes the scenario title.
  void _initTitle() {
    // Create the title element and add it to the html body element.
    html.Element titleElement = new html.Element.tag('h2')
      ..id = 'title'
      ..text = scenario.title;
    html.document.body.children.add(titleElement);
  }

  /// Initialize the [stage], [renderLoop], [juggler], and [resourceManager].
  void _initStage() {
    // Create the canvas element and add it to the html body element.
    html.CanvasElement stageCanvas = new html.CanvasElement()
      ..id = 'stage';
    html.document.body.children.add(stageCanvas);

    // Init the Stage.
    stage = new Stage(stageCanvas,
        width: widthInPixels,
        height: heightInPixels + marginTop + marginBottom,
        frameRate: 30,
        webGL: true);

    renderLoop = new RenderLoop()
        ..addStage(stage);
    juggler = renderLoop.juggler;
  }

  /// Draws the worlds background.
  void _drawBackground() {
    fields.forEach((field) {
      var coords = cellToPixel(field.x, field.y);
      var tileBitmap = new BitmapZ(field.image);
      tileBitmap
          ..x = coords.x
          ..y = coords.y
          ..layer = field.y
          ..zIndex = field.zIndex
          ..pivotX = tileBitmap.width / 2
          ..pivotY = tileBitmap.height / 2;
      addChild(tileBitmap);
    });
  }

  /// Initializes the slider to change the speed.
  void _initSpeedSlider() {
    html.InputElement slider = new html.InputElement(type: 'range');
    slider..id = 'speed-slider'
        ..min = '0'
        ..max = '100'
        ..value = '${100 - _logValueToSlider(speed.inMilliseconds)}'
        ..step = '1'
        ..onChange.listen((_) {
          int sliderValue = 100 - math.max(0, math.min(100, int.parse(slider.value)));
          int ms = _logSliderToValue(sliderValue);

          // Set the new speed.
          speed = new Duration(milliseconds: ms);
        });

    html.document.body.children.add(slider);
  }

  /// Converts the [sliderValue] to a speed value in milliseconds.
  int _logSliderToValue(int sliderValue) {
    int minSlider = 0;
    int maxSlider = 100;

    double minValue = math.log(10);
    double maxValue = math.log(1500);

    // Calculate adjustment factor.
    double scale = (maxValue - minValue) / (maxSlider - minSlider);

    return math.exp(minValue + scale * (sliderValue - minSlider)).round();
  }

  /// Converts the speed [value] to a slider value.
  int _logValueToSlider(int value) {
    int minSlider = 0;
    int maxSlider = 100;

    double minValue = math.log(10);
    double maxValue = math.log(1500);

    // Calculate adjustment factor.
    double scale = (maxValue - minValue) / (maxSlider - minSlider);

    return ((math.log(value) - minValue) / scale + minSlider).round();
  }

  /// Checks the action queue if there are actions to be executed. If there are
  /// actions, one action is executed and removed from the queue.
  void _executeNextAction() {
    if (_actionQueue.isNotEmpty) {
      // Get the current time in milliseconds.
      num currentTime = juggler.elapsedTime * 1000;

      if (currentTime > _nextActionTime) {
        _nextActionTime = currentTime + speed.inMilliseconds;

        PlayerAction action = _actionQueue.removeFirst();
        try {
          // Only use 75% of the duration for the actual action to allow a break.
          double actionDuration = speed.inMilliseconds * .7 / 1000;
          Animatable actionAnim = action(actionDuration);
          juggler.add(actionAnim);
        } on PlayerException catch(e) {
          // Show the exception to the user.
          html.window.alert(e.toString());
          _enterFrameSub.cancel();
        }
      }
    }
  }

  /// Translates a cell coordinate into pixel.
  ///
  /// The returned point is always the center of the cell.
  static Point cellToPixel(num x, num y) {
    return new Point(
        x * cellWidth + (cellWidth / 2),
        y * cellHeight + (cellHeight / 2) + marginTop);
  }

  /// Returns the point that is a number of [steps] away from [x], [y] in
  /// the specified [direction].
  static Point getPointInFront(int x, int y, Direction direction, [int steps = 1]) {
    switch (direction) {
      case Direction.right:
        return new Point(x + steps, y);
      case Direction.down:
        return new Point(x, y + steps);
      case Direction.left:
        return new Point(x - steps, y);
      case Direction.up:
        return new Point(x, y - steps);
    }

    // It's not possible to get here, but this will shut up the warning.
    // TODO: Remove this once it gets fixed.
    return null;
  }
}

/// The type for a [Player] action function.
///
/// The [duration] is the time that is available to the action in seconds.
typedef Animatable PlayerAction(double duration);


/// Extends [Bitmap] to have a z-order.
class BitmapZ extends Bitmap implements DisplayObjectZ {

  @override
  int layer = 0;

  @override
  int zIndex = 0;

  BitmapZ([BitmapData bitmapData = null]) : super(bitmapData);

}

/// Extends [FlipBook] to have a z-order.
class FlipBookZ extends FlipBook implements DisplayObjectZ {

  @override
  int layer = 0;

  @override
  int zIndex = 0;

  FlipBookZ(List<BitmapData> bitmapDatas, [int frameRate = 30, bool loop = true]) :
    super(bitmapDatas, frameRate, loop);
}

/// Extends [DisplayObject] to have a z-order.
abstract class DisplayObjectZ extends DisplayObject implements ZOrder {}

/// Class to provide information about the z-order.
abstract class ZOrder {

  /// Layer.
  int layer;

  /// The stack order of this element inside a layer.
  ///
  /// An element with greater stack order is always in front of an element with
  /// lower stack order.
  int zIndex;

  /// Function to compare two display objects via their [ZOrder] (if they
  /// implement it).
  static int compare(a, b) {
    if (a is ZOrder) {
      if (b is ZOrder) {
        ZOrder aOrder = a as ZOrder;
        ZOrder bOrder = b as ZOrder;

        if (aOrder.layer != bOrder.layer) {
          return aOrder.layer.compareTo(bOrder.layer);

        } else {
          // Same layer. Must compare z-index.
          return aOrder.zIndex.compareTo(bOrder.zIndex);
        }

      } else {
        // b is not a ZOrder.
        return -1;
      }

    } else {
      // a is not a ZOrder.
      return 1;
    }
  }
}
