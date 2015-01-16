part of hello_dart;

class MessagesDe extends Messages {

  @override
  String cantMoveBecauseOfTree() =>
      "Der Spieler kann sich nicht bewegen wegen einem Baum!";

  @override
  String cantMoveBecauseOfBox() =>
      "Der Spieler kann sich nicht bewegen, da die Box nicht geschoben werden kann!";

  @override
  String cantPutStar() =>
      "Der Spieler kann keinen Stern auf ein Feld legen, auf dem schon einer ist!";

  @override
  String cantRemoveStar() =>
      "Der Spieler kann hier keinen Stern auflesen!";

  @override
  String playerExceptionDefault() =>
      "Der Spieler hat irgendein Problem!";

  @override
  String actionOverflowException() =>
      "Ihr Programm dauert zu lange oder beendet gar nicht!";

  @override
  String scenarioNotFoundException(String file) =>
      "Konnte die Szenario-Datei nicht finden: $file";

  @override
  String scenarioInvalid([String file]) {
    if (file == null) {
      return "Das Szenario ist ungültig.";
    } else {
      return "Das Szenario ist ungültig: $file";
    }
  }
}