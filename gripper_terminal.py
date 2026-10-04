import serial
import serial.tools.list_ports
import threading
import time
import sys

BAUD = 9600
MIN_WIDTH = 51.0
MAX_WIDTH = 70.0
PORT_HINTS = ["JDY", "SPP", "Bluetooth", "bluetooth"]

running = True

def find_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        text = f"{p.device} {p.description} {p.manufacturer}".lower()
        if any(h.lower() in text for h in PORT_HINTS):
            return p.device

    if len(ports) == 1:
        return ports[0].device

    return None

def reader(ser):
    while running:
        try:
            line = ser.readline().decode(errors="ignore").strip()
            if line:
                print(f"[CHWYTAK] {line}")
        except Exception as e:
            print(f"[BŁĄD ODCZYTU] {e}")
            break

def validate_command(cmd):
    parts = cmd.split()
    if not parts:
        return False

    command = parts[0].upper()
    if command == "WIDTH":
        if len(parts) != 2:
            print("Użycie: WIDTH <szerokość>, zakres: 51-70 mm")
            return False
    elif command == "GRAB":
        if len(parts) == 1:
            return True
        if len(parts) != 2:
            print("Użycie: GRAB [szerokość], zakres: 51-70 mm")
            return False
    else:
        return True

    try:
        width = float(parts[1])
    except ValueError:
        print(f"Szerokość musi być liczbą z zakresu {MIN_WIDTH:g}-{MAX_WIDTH:g} mm.")
        return False

    if not MIN_WIDTH <= width <= MAX_WIDTH:
        print(f"Szerokość musi być z zakresu {MIN_WIDTH:g}-{MAX_WIDTH:g} mm.")
        return False

    return True

def main():
    global running

    #port = 'COM3'
    port = find_port()
    if not port:
        print("Nie znaleziono portu Bluetooth.")
        print("Dostępne porty:")
        for p in serial.tools.list_ports.comports():
            print(f" - {p.device} | {p.description}")
        return

    print(f"Używam portu: {port}")

    try:
        ser = serial.Serial(port, BAUD, timeout=1)
    except Exception as e:
        print(f"Nie udało się otworzyć portu {port}: {e}")
        return

    time.sleep(2)
    print("Połączono.")
    print("Komendy: ZERO, GRAB, GRAB 65, WIDTH 65, RELEASE, STATUS, exit")

    t = threading.Thread(target=reader, args=(ser,), daemon=True)
    t.start()

    try:
        while True:
            cmd = input("> ").strip()
            if not cmd:
                continue
            if cmd.lower() == "exit":
                ser.write("ZERO\n".encode())
                break
            if not validate_command(cmd):
                continue
            ser.write((cmd + "\n").encode())
    except KeyboardInterrupt:
        pass
    finally:
        running = False
        ser.close()
        print("Rozłączono.")

if __name__ == "__main__":
    main()