import math
import socket
from dataclasses import dataclass
from threading import Lock

from .config import CobotConfig
from .exceptions import (
    CobotConnectionError,
    CobotNotConnectedError,
    InvalidPoseError,
)


@dataclass(frozen=True)
class Pose:
    """
    Pozycja TCP robota.

    x, y, z:
        Pozycja w metrach.

    rx, ry, rz:
        Orientacja jako wektor rotacji w radianach.
    """

    x: float
    y: float
    z: float
    rx: float
    ry: float
    rz: float

    def __post_init__(self):
        values = (
            self.x,
            self.y,
            self.z,
            self.rx,
            self.ry,
            self.rz,
        )

        if not all(
            isinstance(value, (int, float))
            and math.isfinite(value)
            for value in values
        ):
            raise InvalidPoseError(
                "Wszystkie wartości pozycji muszą być "
                "skończonymi liczbami."
            )

    def to_urscript(self):
        return (
            f"p[{self.x}, {self.y}, {self.z}, "
            f"{self.rx}, {self.ry}, {self.rz}]"
        )


class URRobot:
    """
    Minimalny klient URScript dla robotów Universal Robots.

    Biblioteka odpowiada wyłącznie za komunikację i ruch Cobota.
    Nie zawiera obsługi chwytaka.
    """

    def __init__(self, config: CobotConfig):
        self.config = config
        self._socket = None
        self._lock = Lock()

    @property
    def model(self):
        return self.config.model

    @property
    def ip(self):
        return self.config.ip

    @property
    def port(self):
        return self.config.script_port

    def connect(self):
        """
        Łączy się z robotem przez Ethernet.
        """

        if self.is_connected():
            return

        try:
            self._socket = socket.create_connection(
                (
                    self.config.ip,
                    self.config.script_port,
                ),
                timeout=self.config.timeout,
            )
        except OSError as error:
            raise CobotConnectionError(
                f"Nie można połączyć się z robotem "
                f"{self.config.model} pod adresem "
                f"{self.config.ip}:{self.config.script_port}: "
                f"{error}"
            ) from error

        print(
            f"[COBOT] Połączono z {self.config.model} "
            f"({self.config.ip}:{self.config.script_port})"
        )

    def disconnect(self):
        """
        Zatrzymuje robota i zamyka połączenie.
        """

        if not self._socket:
            return

        try:
            self.stop()
        except CobotError:
            pass

        try:
            self._socket.close()
        except OSError:
            pass
        finally:
            self._socket = None

        print("[COBOT] Rozłączono.")

    def is_connected(self):
        return self._socket is not None

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.disconnect()

    def send_program(self, body: str):
        """
        Wysyła program URScript do robota.
        """

        self._require_connection()

        if not body.strip():
            raise ValueError(
                "Program URScript nie może być pusty."
            )

        program = (
            "def external_control():\n"
            f"{self._indent(body)}\n"
            "end\n"
            "external_control()\n"
        )

        try:
            with self._lock:
                self._socket.sendall(
                    program.encode("utf-8")
                )
        except OSError as error:
            self._socket = None

            raise CobotConnectionError(
                f"Błąd wysyłania programu do cobota: "
                f"{error}"
            ) from error

    def movej(
        self,
        joints,
        acceleration=1.0,
        velocity=0.5,
    ):
        """
        Ruch stawowy.

        joints:
            Sześć wartości kątów stawów w radianach.
        """

        self._validate_six_values(joints, "joints")

        values = ", ".join(
            str(value)
            for value in joints
        )

        self.send_program(
            f"movej([{values}], "
            f"a={acceleration}, "
            f"v={velocity})"
        )

    def movel(
        self,
        pose: Pose,
        acceleration=0.5,
        velocity=0.1,
    ):
        """
        Ruch liniowy do pozycji TCP.
        """

        self.send_program(
            f"movel({pose.to_urscript()}, "
            f"a={acceleration}, "
            f"v={velocity})"
        )

    def move_relative_base(
        self,
        x=0.0,
        y=0.0,
        z=0.0,
        rx=0.0,
        ry=0.0,
        rz=0.0,
        acceleration=0.5,
        velocity=0.1,
    ):
        """
        Ruch względny względem układu bazowego robota.

        x, y, z:
            Metry.

        rx, ry, rz:
            Radiany.
        """

        offset = Pose(x, y, z, rx, ry, rz)

        self.send_program(
            "current_pose = get_actual_tcp_pose()\n"
            f"offset = {offset.to_urscript()}\n"
            "target_pose = pose_add("
            "current_pose, offset)\n"
            f"movel(target_pose, "
            f"a={acceleration}, "
            f"v={velocity})"
        )

    def move_relative_tool(
        self,
        x=0.0,
        y=0.0,
        z=0.0,
        rx=0.0,
        ry=0.0,
        rz=0.0,
        acceleration=0.5,
        velocity=0.1,
    ):
        """
        Ruch względny względem aktualnego układu narzędzia.

        x, y, z:
            Metry.

        rx, ry, rz:
            Radiany.
        """

        offset = Pose(x, y, z, rx, ry, rz)

        self.send_program(
            "current_pose = get_actual_tcp_pose()\n"
            f"offset = {offset.to_urscript()}\n"
            "target_pose = pose_trans("
            "current_pose, offset)\n"
            f"movel(target_pose, "
            f"a={acceleration}, "
            f"v={velocity})"
        )

    def speedl(
        self,
        x=0.0,
        y=0.0,
        z=0.0,
        rx=0.0,
        ry=0.0,
        rz=0.0,
        acceleration=0.3,
        duration=0.2,
    ):
        """
        Ruch TCP z określoną prędkością.

        x, y, z:
            Prędkości liniowe w m/s.

        rx, ry, rz:
            Prędkości obrotowe w rad/s.

        duration:
            Czas działania komendy w sekundach.
        """

        values = (
            f"[{x}, {y}, {z}, "
            f"{rx}, {ry}, {rz}]"
        )

        self.send_program(
            f"speedl({values}, "
            f"a={acceleration}, "
            f"t={duration})"
        )

    def stop_linear(self):
        """
        Zatrzymuje ruch liniowy TCP.
        """

        if self.is_connected():
            self.send_program("stopl(2.0)")

    def stop(self):
        """
        Zatrzymuje robota.
        """

        if self.is_connected():
            self.stop_linear()

    def _require_connection(self):
        if not self.is_connected():
            raise CobotNotConnectedError(
                "Cobot nie jest połączony."
            )

    @staticmethod
    def _validate_six_values(values, name):
        if len(values) != 6:
            raise ValueError(
                f"{name} musi zawierać dokładnie "
                "6 wartości."
            )

        if not all(
            isinstance(value, (int, float))
            and math.isfinite(value)
            for value in values
        ):
            raise ValueError(
                f"Wartości {name} muszą być "
                "skończonymi liczbami."
            )

    @staticmethod
    def _indent(text):
        return "\n".join(
            f"    {line}"
            for line in text.strip().splitlines()
        )