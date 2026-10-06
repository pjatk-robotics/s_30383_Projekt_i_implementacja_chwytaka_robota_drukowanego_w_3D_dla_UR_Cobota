from dataclasses import dataclass


@dataclass(frozen=True)
class CobotConfig:
    model: str
    ip: str
    script_port: int = 30002
    timeout: float = 3.0

    def __post_init__(self):
        if not self.model:
            raise ValueError("Model cobota nie może być pusty.")

        if not self.ip:
            raise ValueError("Adres IP nie może być pusty.")

        if not 1 <= self.script_port <= 65535:
            raise ValueError("Niepoprawny numer portu.")

        if self.timeout <= 0:
            raise ValueError("Timeout musi być większy od zera.")