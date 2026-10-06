from dataclasses import dataclass


@dataclass(frozen=True)
class CobotConfig:
    """
    Konfiguracja konkretnego cobota.

    ip:
        Adres IP robota w sieci Ethernet.

    model:
        Model robota, np. UR7e, UR5e, UR10e.

    script_port:
        Port URScript. Dla robotów Universal Robots
        standardowo używany jest port 30002.

    timeout:
        Czas oczekiwania na połączenie w sekundach.
    """

    model: str
    ip: str
    script_port: int = 30002
    timeout: float = 3.0

    def __post_init__(self):
        if not self.model.strip():
            raise ValueError("Model cobota nie może być pusty.")

        if not self.ip.strip():
            raise ValueError("Adres IP nie może być pusty.")

        if not 1 <= self.script_port <= 65535:
            raise ValueError(
                "Port musi być liczbą z zakresu 1-65535."
            )

        if self.timeout <= 0:
            raise ValueError(
                "Timeout musi być większy od zera."
            )