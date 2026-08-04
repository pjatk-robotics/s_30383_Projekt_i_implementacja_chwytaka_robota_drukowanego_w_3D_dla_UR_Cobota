import serial
import serial.tools.list_ports
import threading
import time
import sys

BAUD = 9600
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

def main():
    global running

    port = 'COM3'#find_port()
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
            ser.write((cmd + "\n").encode())
    except KeyboardInterrupt:
        pass
    finally:
        running = False
        ser.close()
        print("Rozłączono.")

if __name__ == "__main__":
    main()