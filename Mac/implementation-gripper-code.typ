= Implementacja oprogramowania --- kod Arduino

== Architektura mikrokontrolera

Kod Arduino realizuje trzy główne funkcje:
+ *Sterowanie serwomechanizmem* MG996R na podstawie komend otrzymywanych z interfejsu
+ *Komunikacja dwukierunkowa* przez moduł Bluetooth (SoftwareSerial na pinach 2 i 3)
+ *Monitorowanie stanu* i sygnalizacja wizualna przez diodę LED

== Konfiguracja sprzętu

Mikrokontroler ATmega328P (Arduino Nano) podłączony jest następująco:

#table(
  columns: (auto, auto, auto),
  align: (center, center, left),
  [*Urządzenie*], [*Pin Arduino*], [*Funkcja*],
  [Servo MG996R - sygnał], [10], [PWM do serwomechanizmu],
  [Bluetooth JDY-31-SPP - RX], [2], [Odbieranie danych z modułu BT],
  [Bluetooth JDY-31-SPP - TX], [3], [Wysyłanie danych do modułu BT],
  [Bluetooth JDY-31-SPP - STATE], [4], [Indykator połączenia (input)],
  [Dioda LED statusu], [13], [Sygnalizacja wizualna stanu],
)

== Protokół komunikacji

Wszystkie komendy są przesyłane w postaci tekstowej, zakończone znakiem nowego wiersza (`\n`). Format: `[KOMENDA] [PARAMETR]`.

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  [*Komenda*], [*Parametr*], [*Opis*],
  [ZERO], [brak], [Zerowanie -- palce maksymalnie otwarte (70°)],
  [GRAB], [szerokość (mm)], [Chwytanie obiektu o danej szerokości],
  [WIDTH], [szerokość (mm)], [Ustawienie rozstawu palców bez chwytania],
  [RELEASE], [brak], [Otwarcie palców (pozycja ZERO)],
  [STATUS], [brak], [Wysłanie raportu aktualnego stanu],
)

Przykład sesji:
```
-> ZERO
Pozycja palców: 70 stopni (szerokość: 71 mm)

-> GRAB 65
Chwytanie przedmiotu (rozstaw: 65 mm, pozycja: 135 stopni)
Gotowe.

-> STATUS
Pozycja: 135 stopni | Szerokość: 65 mm | Bluetooth: połączony
```

== Algorytm kalibracji

Serwomechanizm MG996R sterowany jest w zakresie 0°--180°. Kalibracja empiryczna wykazała:
- Kąt 70° → rozstaw palców 71 mm (pozycja otwarta)
- Kąt 140° → rozstaw palców 51 mm (pozycja zamknięta)

Liniowa interpolacja między tymi punktami:
$$"szerokość(kąt)" = 71 - (kąt - 70) times frac(71 - 51, 140 - 70) = 101 - 0.286 times "kąt"$$

Odwrotnie, aby ustawić daną szerokość:
$$"kąt(szerokość)" = (101 - "szerokość") / 0.286$$

Ta zależność umożliwia precyzyjne chwytanie obiektów o zadanej szerokości bez konieczności ręcznej kalibracji dla każdego rozmiaru.

== Obsługa błędów i bezpieczeństwo

Kod implementuje następujące mechanizmy ochronne:

=== Ograniczenie zakresu kątów
Każdy ruch serwomechanizmu jest zablokowany w zakresie 0°--180°. Jeśli komenda przekroczy ten zakres, mikrokontroler automatycznie koryguje wartość do granic.

=== Timeout połączenia Bluetooth
Moduł JDY-31-SPP sygnalizuje stan połączenia przez pin STATE (pin 4):
- HIGH: brak połączenia
- LOW: połączenie aktywne

Jeśli połączenie zostanie przerwane podczas ruchu, palce pozostają w ostatniej znanej pozycji. Można je zresetować komendą ZERO po przywróceniu połączenia.

=== Dioda LED statusu
- *Miganie* (okres 500 ms): oczekiwanie na połączenie
- *Światło ciągłe*: połączenie aktywne
- *Gaszenie podczas ruchu*: serwomechanizm pracuje

== Przepływ danych

```
┌─────────────────┐
│   Urządzenie    │
│  (PC/telefon)   │
└────────┬────────┘
         │ (UART 9600 bps)
         │
┌────────▼──────────────────────┐
│  Moduł Bluetooth JDY-31-SPP    │
│  (pin 2: RX, pin 3: TX)        │
└────────┬──────────────────────┘
         │
┌────────▼──────────────────────────────┐
│      ATmega328P (Arduino Nano)         │
│ - Parsowanie komend (loop)             │
│ - Obliczanie pozycji serwa             │
│ - Wysyłanie sygnału PWM (pin 10)       │
│ - Monitorowanie STATE (pin 4)          │
│ - Raportowanie na UART (pins 2, 3)    │
└────────┬──────────────────────────────┘
         │ (PWM 50 Hz)
         │
┌────────▼──────────────┐
│   Serwomechanizm      │
│     MG996R (pin 10)   │
└───────────────────────┘
```

== Pełny kod

Kod Arduino znajduje się w pliku `gripper_code.ino` w katalogu `arduino/`. Zawiera:
- Inicjalizację sprzętu w `setup()`
- Główną pętlę przetwarzania komend w `loop()`
- Funkcje interpolacji szerokości w `szerokoscNaKat()`
- Obsługę błędów i raportowania statusu

Kod jest w pełni skomentowany i gotowy do wgrania na Arduino Nano za pomocą narzędzia Arduino IDE.
