import subprocess
import sys
import time
from pathlib import Path
from threading import Event, Lock, Thread

from pynput import keyboard

from cobot import CobotConfig, URRobot


# ============================================================
# KONFIGURACJA COBOTA
# ============================================================

ROBOT_CONFIG = CobotConfig(
    model="UR7e",
    ip="192.168.0.10",       # wpisz właściwy adres IP
    script_port=30002,
    timeout=3.0,
)


# ============================================================
# KONFIGURACJA RUCHU
# ============================================================

# Na początku użyj małej wartości, np. 0.001.
LINEAR_SPEED = 0.005

# Prędkość obrotu w rad/s.
ROTATION_SPEED = 0.05

# Częstotliwość wysyłania komend ruchu.
CONTROL_FREQUENCY = 8

# Czas pojedynczej komendy speedl.
SPEED_DURATION = 0.20


# ============================================================
# KONFIGURACJA CHWYTAKA
# ============================================================

GRIPPER_MIN_WIDTH = 51.0
GRIPPER_MAX_WIDTH = 70.0
GRIPPER_WIDTH_STEP = 1.0
gripper_width = 65.0


class GripperTerminal:
    """
    Uruchamia istniejący gripper_terminal.py.

    Ta klasa znajduje się w main.py, ponieważ chwytak
    nie należy do biblioteki cobot.
    """

    def __init__(self):
        self.process = None
        self.lock = Lock()

    def start(self):
        if self.process:
            return

        terminal_path = (
            Path(__file__).resolve().parent
            / "gripper_terminal.py"
        )

        if not terminal_path.exists():
            raise FileNotFoundError(
                f"Nie znaleziono pliku: {terminal_path}"
            )

        self.process = subprocess.Popen(
            [
                sys.executable,
                str(terminal_path),
            ],
            stdin=subprocess.PIPE,
            text=True,
        )

        # Czas na znalezienie portu Bluetooth.
        time.sleep(2)

    def send(self, command):
        if not self.process:
            raise RuntimeError(
                "Terminal chwytaka nie jest uruchomiony."
            )

        if not self.process.stdin:
            raise RuntimeError(
                "Brak wejścia stdin terminala chwytaka."
            )

        with self.lock:
            try:
                self.process.stdin.write(
                    command + "\n"
                )
                self.process.stdin.flush()
            except (BrokenPipeError, OSError) as error:
                raise RuntimeError(
                    "Nie można wysłać komendy "
                    "do terminala chwytaka."
                ) from error

        print(f"[CHWYTAK] {command}")

    def set_width(self, width):
        width = self._validate_width(width)
        self.send(f"WIDTH {width:g}")

    def grab(self, width):
        width = self._validate_width(width)
        self.send(f"GRAB {width:g}")

    def release(self):
        self.send("RELEASE")

    def zero(self):
        self.send("ZERO")

    def close(self):
        if not self.process:
            return

        try:
            self.zero()
            time.sleep(0.2)
            self.send("exit")
            self.process.wait(timeout=3)
        except Exception:
            self.process.kill()
        finally:
            self.process = None
            print("[CHWYTAK] Terminal zamknięty.")

    @staticmethod
    def _validate_width(width):
        width = float(width)

        if not (
            GRIPPER_MIN_WIDTH
            <= width
            <= GRIPPER_MAX_WIDTH
        ):
            raise ValueError(
                "Szerokość chwytaka musi być w zakresie "
                f"{GRIPPER_MIN_WIDTH:g}-"
                f"{GRIPPER_MAX_WIDTH:g} mm."
            )

        return width


class KeyboardController:
    """
    Sterowanie ciągłe.

    Robot porusza się tak długo, jak długo klawisz
    znajduje się w pressed_keys.
    """

    def __init__(self, robot):
        self.robot = robot
        self.pressed_keys = set()
        self.lock = Lock()
        self.running = Event()
        self.thread = None

    def start(self):
        self.running.set()

        self.thread = Thread(
            target=self._control_loop,
            daemon=True,
        )
        self.thread.start()

    def stop(self):
        self.running.clear()

        with self.lock:
            self.pressed_keys.clear()

        try:
            self.robot.stop_linear()
        except Exception:
            pass

    def press(self, key):
        with self.lock:
            self.pressed_keys.add(key)

    def release(self, key):
        with self.lock:
            self.pressed_keys.discard(key)

    def _control_loop(self):
        delay = 1.0 / CONTROL_FREQUENCY

        while self.running.is_set():
            velocity = self._calculate_velocity()

            if velocity is not None:
                try:
                    self.robot.speedl(
                        x=velocity[0],
                        y=velocity[1],
                        z=velocity[2],
                        rz=velocity[5],
                        acceleration=0.3,
                        duration=SPEED_DURATION,
                    )
                except Exception as error:
                    print(f"[COBOT] Błąd ruchu: {error}")
                    self.running.clear()
                    break

            time.sleep(delay)

    def _calculate_velocity(self):
        with self.lock:
            keys = set(self.pressed_keys)

        x = 0.0
        y = 0.0
        z = 0.0
        rz = 0.0

        # WASD
        if self._has_char(keys, "w"):
            x += LINEAR_SPEED

        if self._has_char(keys, "s"):
            x -= LINEAR_SPEED

        if self._has_char(keys, "a"):
            y += LINEAR_SPEED

        if self._has_char(keys, "d"):
            y -= LINEAR_SPEED

        # CTRL / SHIFT
        if (
            keyboard.Key.ctrl_l in keys
            or keyboard.Key.ctrl_r in keys
        ):
            z += LINEAR_SPEED

        if (
            keyboard.Key.shift_l in keys
            or keyboard.Key.shift_r in keys
        ):
            z -= LINEAR_SPEED

        # Strzałki
        if keyboard.Key.up in keys:
            x += LINEAR_SPEED

        if keyboard.Key.down in keys:
            x -= LINEAR_SPEED

        if keyboard.Key.left in keys:
            y += LINEAR_SPEED

        if keyboard.Key.right in keys:
            y -= LINEAR_SPEED

        # Obrót chwytaka
        if self._has_char(keys, "<"):
            rz += ROTATION_SPEED

        if self._has_char(keys, ">"):
            rz -= ROTATION_SPEED

        if x == 0 and y == 0 and z == 0 and rz == 0:
            return None

        return x, y, z, 0.0, 0.0, rz

    @staticmethod
    def _has_char(keys, expected):
        for key in keys:
            try:
                if key.char.lower() == expected:
                    return True
            except AttributeError:
                pass

        return False


def print_help():
    print(
        """
============================================================
STEROWANIE COBOTEM I CHWYTAKIEM
============================================================

RUCH COBOTA:
W                 X+
S                 X-
A                 Y+
D                 Y-

CTRL              Z+
SHIFT             Z-

STRZAŁKA GÓRA    X+
STRZAŁKA DÓŁ     X-
STRZAŁKA LEWO    Y+
STRZAŁKA PRAWO   Y-

<                 obrót chwytaka w jedną stronę
>                 obrót chwytaka w drugą stronę

CHWYTAK:
G                 GRAB z aktualną szerokością
R                 RELEASE
Z                 ZERO

[                 zmniejszenie szerokości
]                 zwiększenie szerokości

ESC               zatrzymanie i wyjście
============================================================
"""
    )


def main():
    global gripper_width

    robot = URRobot(ROBOT_CONFIG)
    gripper = GripperTerminal()
    controller = KeyboardController(robot)

    def on_press(key):
        global gripper_width

        if key == keyboard.Key.esc:
            return False

        try:
            char = key.char.lower()
        except AttributeError:
            char = None

        # Obsługa chwytaka
        if char == "g":
            gripper.grab(gripper_width)
            print(
                f"[CHWYTAK] GRAB {gripper_width:g} mm"
            )
            return

        if char == "r":
            gripper.release()
            return

        if char == "z":
            gripper.zero()
            return

        # Zmiana szerokości chwytaka
        if char == "[":
            gripper_width = max(
                GRIPPER_MIN_WIDTH,
                gripper_width - GRIPPER_WIDTH_STEP,
            )

            gripper.set_width(gripper_width)
            print(
                f"[CHWYTAK] Szerokość: "
                f"{gripper_width:g} mm"
            )
            return

        if char == "]":
            gripper_width = min(
                GRIPPER_MAX_WIDTH,
                gripper_width + GRIPPER_WIDTH_STEP,
            )

            gripper.set_width(gripper_width)
            print(
                f"[CHWYTAK] Szerokość: "
                f"{gripper_width:g} mm"
            )
            return

        # Obsługa ruchu Cobota
        controller.press(key)

    def on_release(key):
        controller.release(key)

    try:
        print_help()

        robot.connect()
        gripper.start()
        controller.start()

        print(
            f"[INFO] Gotowy: {ROBOT_CONFIG.model} "
            f"{ROBOT_CONFIG.ip}:"
            f"{ROBOT_CONFIG.script_port}"
        )

        print(
            f"[INFO] Początkowa szerokość chwytaka: "
            f"{gripper_width:g} mm"
        )

        with keyboard.Listener(
            on_press=on_press,
            on_release=on_release,
        ) as listener:
            listener.join()

    except ConnectionError as error:
        print(f"[BŁĄD COBOTA] {error}")

    except (RuntimeError, FileNotFoundError) as error:
        print(f"[BŁĄD SYSTEMU] {error}")

    except KeyboardInterrupt:
        print("\n[INFO] Przerwano klawiaturą.")

    finally:
        print("[INFO] Zatrzymywanie systemu.")

        controller.stop()
        gripper.close()
        robot.disconnect()

        print("[INFO] Program zakończony.")


if __name__ == "__main__":
    main()