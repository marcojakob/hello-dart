part of hello_dart;

/// Superclass for all Hello Dart exceptions.
class HelloDartException implements Exception {}

/// Exception for errors created by the user who implemented the start()-method.
class PlayerException implements HelloDartException {

  /// A message describing the player exception.
  final String message;

  /// Creates a new [PlayerException] with an optional error [message].
  PlayerException([this.message = '']);

  @override
  String toString() {
    if (message != null && message.isNotEmpty) {
      return message;
    } else {
      return messages.playerExceptionDefault();
    }
  }
}

/// Exception that is thrown when the user created a start()-method that does
/// not terminate in a reasonable time. That means it calls more than the
/// allowed number of [Player] action methods ([World.maxActions]).
class ActionOverflowException extends PlayerException {
  ActionOverflowException([String message = '']) : super(message);
}

/// Exception used to stop the execution inside the start()-method.
class StopException implements HelloDartException {}


/// Exception for errors when parsing the scenario.
class ScenarioException implements HelloDartException {
  final message;

  ScenarioException(this.message);

  @override
  String toString() {
    if (message == null) {
      return "ScenarioException";
    }
    return "$message";
  }
}

