part of hello_dart;

class Messages {
  String cantMoveBecauseNoField() => "I can't move because there is no field!";

  String cantMoveBecauseOfTree() => "I can't move because of a tree!";

  String cantMoveBecauseOfBox() =>
      "I can't move because the box can't be pushed!";

  String cantPutStar() => "I can't put a star on top of another star!";

  String cantRemoveStar() => "There is no star that I could remove!";

  String playerExceptionDefault() =>
      "I have a problem, but I don't know what it is, sorry!";

  String actionOverflowException() =>
      "Your program takes too long to execute or doesn't end at all!";

  String fileNotFoundException() =>
      "Could not load a file: Please check your scenario and image files.";

  String scenarioInvalid() => "The scenario is invalid.";
}
