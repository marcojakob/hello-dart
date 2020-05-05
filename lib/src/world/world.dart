part of hello_dart;

/// This class creates a world for the player and manages all other actors.
class World extends Sprite {
  /// The asset directory.
  static const String imagesDir = 'packages/hello_dart/images';

  /// The width of one cell in pixels.
  static int cellWidth = 100;

  /// The height of one cell in pixels.
  static int cellHeight = 80;

  static int marginTop = 80;
  static int marginBottom = 46;

  /// The maximum number of allowed calls to the player's action methods.
  static const int maxActionCalls = 10000;

  /// The maximum number of allowed calls to the player's sensor methods.
  static const int maxSensorCalls = 100000;

  /// The scenario of this world.
  Scenario scenario;

  /// Instance of [Player] that contains the user's program.
  Player player;

  /// The duration between the execution of actions (in seconds).
  num speed;

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
  int get widthInPixels => widthInCells * cellWidth + 1;

  /// Returns the world's height in pixels (without margins).
  int get heightInPixels =>
      heightInCells * cellHeight + marginTop + marginBottom;

  /// A Queue of player actions waiting to be executed.
  final Queue<PlayerAction> _actionQueue = Queue();

  /// A counter to detect infinite loops in sensor methods.
  ///
  /// When a large number of method calls are detected without any changes on
  /// screen, we can assume that the user's program does not terminate.
  int _sensorCallCounter = 0;

  /// The subscription for enter frame events.
  StreamSubscription _enterFrameSub;

  /// The time when the next action may be executed, in seconds.
  num _nextActionTime = 0;

  /// The animatable of the currently executing action.
  Animatable _actionAnimatable;

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
      scenario =
          Scenario.parse(resourceManager.getTextFile('scenario'), scenarioFile);
      scenario.build(this);

      // Init body.
      _initBody();

      // Init the scenario title.
      _initTitle();

      // Init the stage.
      _initStage();

      // Init the render loop and juggler.
      renderLoop = RenderLoop()..addStage(stage);
      juggler = renderLoop.juggler;

      // The first execution should wait one cycle for the user to see it.
      _nextActionTime = speed;

      // Init the speed slider.
      _initSpeedSlider();

      stage.addChild(this);

      // Draw the fields.
      _drawFields();

      // Add actors.
      actors.forEach((actor) => actor._bitmapAddToWorld());

      // Sort the fields and actors.
      sortChildren(_displayObjectCompare);

      // Execute the user's start()-method. This will fill the action queue.
      try {
        player.start();
      } on StopException {
        // Stop execution after all queued actions have been processed.
        _actionQueue.add((spd) {
          _enterFrameSub.cancel();
          return null;
        });
      } on PlayerException catch (e) {
        // Stop execution after all queued actions have been processed, then
        // show the exception to the user.
        _actionQueue.add((spd) {
          _enterFrameSub.cancel();
          html.window.alert(e.toString());
          return null;
        });
      }

      // Start listening to enter frame events of the browser's event loop.
      _enterFrameSub = onEnterFrame.listen((_) => _executeNextAction());
    });
  }

  /// Queues the specified [action] to be executed at a later time.
  void queueAction(PlayerAction action) {
    // Add the current world state at the end of the queue.
    _actionQueue.add(action);

    if (_actionQueue.length > maxActionCalls) {
      // The maximum number of action method calls during one act()-call has
      // been reached.
      throw OverflowException(messages.actionOverflowException());
    }
  }

  /// Detects an infinite loop and terminates.
  ///
  /// There are two
  /// When a large number of method calls are detected without any changes on
  /// screen (sensor methods), we can assume that the user's program does not
  /// terminate.
  void _detectSensorCallOverflow() {
    _sensorCallCounter++;

    if (_sensorCallCounter > maxSensorCalls) {
      // The maximum number of sensor method calls during one act()-call has
      // been reached.
      throw OverflowException(messages.actionOverflowException());
    }
  }

  /// Returns the field at the specified location or null, if there is no field.
  Field getFieldAt(int x, int y) {
    _detectSensorCallOverflow();

    return fields.firstWhere((field) => field.x == x && field.y == y,
        orElse: () => null);
  }

  /// Returns the field that is a number of [steps] away from [x], [y]
  /// in the specified [direction].
  Field getFieldInFront(int x, int y, Direction direction, [int steps = 1]) {
    _detectSensorCallOverflow();

    Point<int> p = World.getPointInFront(x, y, direction, steps);

    return getFieldAt(p.x, p.y);
  }

  /// Returns a list of actors at the specified location.
  List<Actor> getActorsAt(int x, int y) {
    _detectSensorCallOverflow();

    return actors
        .where((Actor actor) => actor.x == x && actor.y == y)
        .toList(growable: false);
  }

  /// Returns a list of actors that are a number of [steps] away from [x], [y]
  /// in the specified [direction].
  List<Actor> getActorsInFront(int x, int y, Direction direction,
      [int steps = 1]) {
    _detectSensorCallOverflow();

    Point<int> p = World.getPointInFront(x, y, direction, steps);

    return getActorsAt(p.x, p.y);
  }

  /// Adds the [child] at the correct z-order position.
  void addChildAtZOrder(DisplayObjectZ child) {
    addChildAt(child, _getChildIndexForZOrder(child));
  }

  /// Recalculates the correct child index of [child] and updates it.
  void updateChildIndexZOrder(DisplayObjectZ child) {
    setChildIndex(
        child, math.min(_getChildIndexForZOrder(child), numChildren - 1));
  }

  /// Returns the correct child index where a child with [order] should be
  /// inserted.
  int _getChildIndexForZOrder(DisplayObjectZ order) {
    for (int i = 0; i < numChildren; i++) {
      if (_displayObjectCompare(getChildAt(i), order) > 0) {
        return i;
      }
    }
    return numChildren;
  }

  /// Loads all assets.
  /// Assets are finished loading when the returned [Future] completes.
  Future<ResourceManager> _loadAssets(String scenarioFile) {
    Completer<ResourceManager> completer = Completer();

    resourceManager = ResourceManager();

    resourceManager
      ..addBitmapData('field', '${imagesDir}/${field}.png')
      ..addBitmapData('star', '${imagesDir}/star.png')
      ..addBitmapData('box', '${imagesDir}/box.png')
      ..addBitmapData('tree', '${imagesDir}/tree.png')
      ..addTextureAtlas('character', '${imagesDir}/${character}.json',
          TextureAtlasFormat.JSONARRAY)
      ..addTextureAtlas('speech-bubble', '${imagesDir}/speech-bubble.json',
          TextureAtlasFormat.JSONARRAY)
      ..addTextFile('scenario', scenarioFile);

    resourceManager.load().then((manager) {
      completer.complete(manager);
    }).catchError((error) {
      completer.completeError(
          FileNotFoundException(messages.fileNotFoundException()));
    });

    return completer.future;
  }

  /// Initializes the html body.
  void _initBody() {
    html.document.body.style
      ..margin = '0 10px'
      ..padding = '0'
      ..overflow = 'hidden'
      ..fontFamily = 'Helvetica Neue, Helvetica, Arial, sans-serif'
      ..display = 'flex'
      ..height = '100vh'
      ..flexDirection = 'column'
      ..justifyContent = 'center'
      ..setProperty('flex-pack', 'center') // For IE10.
      ..alignItems = 'center'
      ..setProperty('flex-align', 'center') // For IE10.
      ..background =
          'linear-gradient(${backgroundColorTop}, ${backgroundColorBottom})';
  }

  /// Initializes the scenario title.
  void _initTitle() {
    // Create the title element and add it to the html body element.
    html.Element titleElement = html.Element.tag('h2')
      ..id = 'title'
      ..text = scenario.title;

    titleElement.style
      ..maxWidth = '100%'
      ..fontWeight = 'normal'
      ..fontFamily = 'Lilita One, Helvetica Neue, Helvetica, Arial, sans-serif'
      ..fontSize = '40px'
      ..marginTop = '10px'
      ..marginBottom = '5px'
      ..whiteSpace = 'nowrap'
      ..color = 'white'
      ..textShadow = '-1px 0 black, 0 1px black, 1px 0 black, 0 -1px black,'
          '0px 4px 3px rgba(0,0,0,0.4),'
          '0px 8px 13px rgba(0,0,0,0.1)';
    html.document.body.children.add(titleElement);
  }

  /// Initialize the [stage], [renderLoop], [juggler], and [resourceManager].
  void _initStage() {
    // Create the canvas element and add it to the html body element.
    html.CanvasElement stageCanvas = html.CanvasElement()
      ..id = 'stage'
      ..style.width = '100%'
      ..style.height = 'calc(100% - 120px)'
      ..style.maxHeight = '${heightInPixels}px'
      ..style.maxWidth = '${widthInPixels}px';
    html.document.body.children.add(stageCanvas);

    // Init the Stage.
    var options = StageOptions()
          ..transparent = true
          ..backgroundColor =
              0x00 // First two numbers after x are transparency.
        ;

    stage = Stage(stageCanvas,
        width: widthInPixels, height: heightInPixels, options: options);
  }

  /// Draws the worlds background.
  void _drawFields() {
    fields.forEach((field) {
      var coords = cellToPixel(field.x, field.y);
      var tileBitmap = BitmapZ(field.image);
      tileBitmap
        ..x = coords.x
        ..y = coords.y
        ..layer = field.y
        ..zIndex = field.zIndex
        ..pivotX = (tileBitmap.width / 2).floor()
        ..pivotY = (tileBitmap.height / 2).floor();
      addChild(tileBitmap);
    });
  }

  /// Initializes the slider to change the speed.
  void _initSpeedSlider() {
    html.InputElement slider = html.InputElement(type: 'range');
    slider
      ..id = 'speed-slider'
      ..min = '0'
      ..max = '100'
      ..value = '${100 - _logValueToSlider(speed)}'
      ..step = '1'
      ..onChange.listen((_) {
        int sliderValue =
            100 - math.max<int>(0, math.min<int>(100, int.parse(slider.value)));

        // Set the new speed.
        speed = _logSliderToValue(sliderValue);
      });

    slider.style
      ..padding = '5px 0'
      ..marginTop = '25px'
      ..marginBottom = '15px'
      ..width = '100%'
      ..maxWidth = '200px';

    html.document.body.children.add(slider);
  }

  /// Converts the [sliderValue] to a speed value in seconds.
  num _logSliderToValue(int sliderValue) {
    int minSlider = 0;
    int maxSlider = 100;

    double minValue = math.log(10);
    double maxValue = math.log(1500);

    // Calculate adjustment factor.
    double scale = (maxValue - minValue) / (maxSlider - minSlider);

    return math.exp(minValue + scale * (sliderValue - minSlider)).round() /
        1000;
  }

  /// Converts the speed [value] (in seconds) to a slider value.
  int _logValueToSlider(num value) {
    num ms = value * 1000;

    int minSlider = 0;
    int maxSlider = 100;

    double minValueMs = math.log(10);
    double maxValueMs = math.log(1500);

    // Calculate adjustment factor.
    double scale = (maxValueMs - minValueMs) / (maxSlider - minSlider);

    return ((math.log(ms) - minValueMs) / scale + minSlider).round();
  }

  /// Checks the action queue if there are actions to be executed. If there are
  /// actions, one action is executed and removed from the queue.
  void _executeNextAction() {
    if (_actionQueue.isNotEmpty) {
      // Get the current time.
      num currentTime = juggler.elapsedTime;

      // Test if the time is ready.
      if (currentTime > _nextActionTime) {
        // Test if last action is still animating in the juggler.
        if (_actionAnimatable != null &&
            juggler.contains(_actionAnimatable) &&
            _actionAnimatable.advanceTime(0.01)) {
          return;
        }

        // ---
        // We can execute the next action.
        // ---
        _nextActionTime = currentTime + speed;

        // Resets the sensor method call counter.
        _sensorCallCounter = 0;

        PlayerAction action = _actionQueue.removeFirst();
        try {
          // Only use 70% of the duration for the actual action to allow a break.
          double actionDuration = speed.toDouble() * .7;

          // Execute the player action.
          _actionAnimatable = action(actionDuration);

          if (_actionAnimatable != null) {
            juggler.add(_actionAnimatable);
          }
        } on PlayerException catch (e) {
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
  static Point<int> cellToPixel(int x, int y) {
    return Point((x * cellWidth + (cellWidth / 2)).round(),
        (y * cellHeight + (cellHeight / 2) + marginTop).round());
  }

  /// Returns the point that is a number of [steps] away from [x], [y] in
  /// the specified [direction].
  static Point<int> getPointInFront(int x, int y, Direction direction,
      [int steps = 1]) {
    switch (direction) {
      case Direction.right:
        return Point(x + steps, y);
      case Direction.down:
        return Point(x, y + steps);
      case Direction.left:
        return Point(x - steps, y);
      case Direction.up:
        return Point(x, y - steps);
    }

    // We only get here if direction was null.
    throw ArgumentError.notNull('direction');
  }
}

/// The type for a [Player] action function.
///
/// The [duration] is the time that is available to the action (in seconds).
///
/// The function must return an [Animatable] or null if there is nothing to
/// be animated.
typedef Animatable PlayerAction(double duration);

/// Extends [Bitmap] to have a z-order.
class BitmapZ extends Bitmap implements DisplayObjectZ {
  @override
  int layer = 0;

  @override
  int zIndex = 0;

  BitmapZ([BitmapData bitmapData]) : super(bitmapData);
}

/// Extends [FlipBook] to have a z-order.
class FlipBookZ extends FlipBook implements DisplayObjectZ {
  @override
  int layer = 0;

  @override
  int zIndex = 0;

  FlipBookZ(List<BitmapData> bitmapDatas,
      [int frameRate = 30, bool loop = true])
      : super(bitmapDatas, frameRate, loop);

  /// TODO: This only a hack because of bug
  /// https://github.com/bp74/StageXL/issues/178
  /// Should be removed when the bug is fixed.
  @override
  bool advanceTime(num time) {
    bool result = super.advanceTime(time);

    if (!loop && currentFrame == totalFrames - 1) {
      return false;
    }

    return result;
  }
}

/// Extends [Sprite] to have a z-order.
class SpriteZ extends Sprite implements DisplayObjectZ {
  @override
  int layer = 0;

  @override
  int zIndex = 0;
}

/// Extends [DisplayObject] to have a z-order.
abstract class DisplayObjectZ extends DisplayObject {
  /// Layer.
  int layer = 0;

  /// The stack order of this element inside a layer.
  ///
  /// An element with greater stack order is always in front of an element with
  /// lower stack order.
  int zIndex = 0;
}

/// Function to compare two [DisplayObject]s via their layer and zIndex if
/// they implement [DisplayObjectZ].
int _displayObjectCompare(DisplayObject a, DisplayObject b) {
  if (a is DisplayObjectZ) {
    if (b is DisplayObjectZ) {
      if (a.layer != b.layer) {
        return a.layer.compareTo(b.layer);
      } else {
        // Same layer. Must compare z-index.
        return a.zIndex.compareTo(b.zIndex);
      }
    } else {
      // b is not a DisplayObjectZ.
      return -1;
    }
  } else {
    // a is not a DisplayObjectZ.
    return 1;
  }
}
