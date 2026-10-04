= Implementacja oprogramowania --- interfejs Python

== Interfejs użytkownika

Terminal Python (`gripper_terminal.py`) stanowi interfejs komunikacji między operatorem a chwytakiem. Umożliwia wysyłanie komend, monitorowanie statusu i diagnostykę połączenia Bluetooth.

== Architektura programu

Program zbudowany jest na trzech głównych komponentach:
+ *Auto-discovery* portu Bluetooth (wyszukiwanie JDY-31-SPP lub HC-05/HC-06)
+ *Obsługa połączenia szeregowego* (UART 9600 bps, timeout odczytu)
+ *Interfejs interaktywny* (CLI z historią komend i echowaniem)

== Wymagania systemowe

#table(
  columns: (auto, auto),
  align: (left, left),
  [*Komponent*], [*Wymaganie*],
  [Python], [3.8 lub nowsza],
  [Biblioteka pyserial], [3.5+],
  [System operacyjny], [Linux, macOS (Sonoma+), Windows 10/11],
  [Bluetooth], [Interfejs SPP (Serial Port Profile) obsługiwany],
)

Instalacja zależności:
```bash
pip install pyserial
```

== Auto-discovery portu Bluetooth

Program automatycznie wyszukuje port Bluetooth, badając dostępne porty szeregowe i ich opisy:
- Na macOS szuka `/dev/cu.JDY-31-SPP` lub `/dev/cu.HC-05/HC-06`
- Na Windows szuka `COM*` z opisem zawierającym "Bluetooth" lub "JDY"
- Na Linuxie szuka `/dev/rfcomm0` lub `/dev/ttyUSB*`

Jeśli program nie znajdzie portu automatycznie, wyświetla listę dostępnych portów szeregowych i prosi użytkownika o wybór.

== Sesja interaktywna

Po uruchomieniu program łączy się z chwytakiem i wyświetla menu:
```
========================================
    Terminal Sterujący Chwytakiem
========================================
Port: /dev/cu.JDY-31-SPP
Połączenie: AKTYWNE
Bauds: 9600
========================================

Dostępne komendy:
  ZERO              - Otwarcie palców (pozycja bezpieczna)
  GRAB [szerokość]  - Chwytanie obiektu (np. GRAB 65)
  WIDTH [szerokość] - Ustawienie rozstawu (np. WIDTH 70)
  RELEASE           - Otwarcie palców
  STATUS            - Raport aktualnego stanu

Wpisz komendę (lub 'help' dla listy):
```

== Protokół transakcji

Każda komenda wysłana do chwytaka generuje echo i odpowiedź:

```
> GRAB 65
Wysyłanie: GRAB 65

[Arduino odpisuje]
Pozycja: 135 stopni | Szerokość: 65 mm
Gotowe.

[Opóźnienie ~500 ms dla ruchu serwa]
```

== Obsługa błędów

Program obsługuje następujące sytuacje awaryjne:
- *Brak połączenia z portem*: wyświetla listę dostępnych portów
- *Timeout* (brak odpowiedzi Arduino >2s): sygnalizuje rozłączenie
- *Niepoprawna komenda*: Arduino zwraca "Nieznana komenda!"
- *Fizyczne rozłączenie Bluetooth*: program automatycznie próbuje ponownie połączyć się

== Rejestracja sesji

Program może zapisywać do dziennika wszystkie wysłane komendy i odpowiedzi Arduino. Plik dziennika zawiera znaczniki czasowe i jest przydatny do diagnostyki.

Przykładowy dziennik (`gripper_log.txt`):
```
[09:45:23.120] > ZERO
[09:45:23.580] < Pozycja palców: 70 stopni (szerokość: 71 mm)
[09:45:25.100] > GRAB 65
[09:45:25.780] < Chwytanie przedmiotu (rozstaw: 65 mm, pozycja: 135 stopni)
[09:45:25.781] < Gotowe.
[09:45:30.200] > STATUS
[09:45:30.250] < Pozycja: 135 stopni | Szerokość: 65 mm | Bluetooth: połączony
```

== Integracja z UR5e

Terminal Python może być zaadaptowany do komunikacji z robotem UR5e. W przyszłych fazach projekt przewiduje:
- Połączenie terminala z biblioteką `ur_rtde`
- Synchronizacja ruchu robota i chwytaka
- Automatyczne wysyłanie komend na podstawie sekwencji pick-and-place zdefiniowanej w programie robota

Architektura będzie wyglądać następująco:
```
┌──────────────────────┐
│   Program UR5e       │
│   (URScript/Python)  │
└──────────┬───────────┘
           │
┌──────────▼──────────────┐
│  Python Robot Control   │
│   (ur_rtde integration) │
└──────────┬──────────────┘
           │
┌──────────▼──────────────┐
│  gripper_terminal.py    │
│  (Bluetooth interface)  │
└──────────┬──────────────┘
           │
┌──────────▼──────────────┐
│   Arduino + JDY-31-SPP  │
│   (Servo control)       │
└─────────────────────────┘
```

== Kompilacja i uruchomienie

Uruchomienie programu:
```bash
python gripper_terminal.py
```

Program automatycznie:
1. Skanuje dostępne porty Bluetooth
2. Łączy się z chwytakiem
3. Wyświetla menu interaktywne
4. Czeka na komendy użytkownika

Aby zamknąć program, wpisz `EXIT` lub naciśnij `Ctrl+C`.
