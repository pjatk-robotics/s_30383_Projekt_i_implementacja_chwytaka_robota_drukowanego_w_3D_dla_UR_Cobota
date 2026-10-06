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

        if not all(math.isfinite(value) for value in values):
            raise InvalidPoseError(
                "Wszystkie wartości pozycji muszą być liczbami."
            )

    def to_urscript(self):
        return (
            f"p[{self.x}, {self.y}, {self.z}, "
            f"{self.rx}, {self.ry}, {self.rz}]"
        )


class URRobot:
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

    def connect(self):
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
                f"Nie można połączyć się z {self.config.model} "
                f"pod adresem {self.config.ip}: "
                f"{error}"
            ) from error

        print(
            f"[COBOT] Połączono z {self.config.model} "
            f"({self.config.ip}:{self.config.script_port})"
        )

    def disconnect(self):
        if not self._socket:
            return

        try:
            self.stop()
        except Exception:
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
        self._require_connection()

        program = (
            "def external_control():\n"
            f"{self._indent(body)}\n"
            "end\n"
            "external_control()\n"
        )

        try:
            with self._lock:
                self._socket.sendall(program.encode("utf-8"))
        except OSError as error:
            self._socket = None
            raise CobotConnectionError(
                f"Błąd wysyłania programu do cobota: {error}"
            ) from error

    def movej(
        self,
        joints,
        acceleration=1.0,
        velocity=0.5,
    ):
        if len(joints) != 6:
            raise ValueError(
                "Lista joints musi zawierać 6 wartości."
            )

        values = ", ".join(str(value) for value in joints)

        self.send_program(
            f"movej([{values}], "
            f"a={acceleration}, v={velocity})"
        )

    def movel(
        self,
        pose: Pose,
        acceleration=0.5,
        velocity=0.1,
    ):
        self.send_program(
            f"movel({pose.to_urscript()}, "
            f"a={acceleration}, v={velocity})"
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
        offset = Pose(x, y, z, rx, ry, rz)

        self.send_program(
            "current_pose = get_actual_tcp_pose()\n"
            f"offset = {offset.to_urscript()}\n"
            "target_pose = pose_add(current_pose, offset)\n"
            f"movel(target_pose, a={acceleration}, "
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
        offset = Pose(x, y, z, rx, ry, rz)

        self.send_program(
            "current_pose = get_actual_tcp_pose()\n"
            f"offset = {offset.to_urscript()}\n"
            "target_pose = pose_trans(current_pose, offset)\n"
            f"movel(target_pose, a={acceleration}, "
            f"v={velocity})"
        )

    def stop(self):
        if self.is_connected():
            self.send_program("stopj(2.0)")

    def _require_connection(self):
        if not self.is_connected():
            raise CobotNotConnectedError(
                "Cobot nie jest połączony."
            )

    @staticmethod
    def _indent(text):
        return "\n".join(
            f"    {line}"
            for line in text.strip().splitlines()
        )