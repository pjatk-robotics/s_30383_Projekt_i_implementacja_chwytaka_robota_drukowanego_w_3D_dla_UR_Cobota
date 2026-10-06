class CobotError(Exception):
    """Bazowy wyjątek biblioteki cobot."""


class CobotConnectionError(CobotError):
    """Błąd połączenia lub komunikacji z robotem."""


class CobotNotConnectedError(CobotError):
    """Próba użycia robota bez aktywnego połączenia."""


class InvalidPoseError(CobotError):
    """Niepoprawna pozycja lub orientacja TCP."""