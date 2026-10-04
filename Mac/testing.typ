= Plan testowania i walidacji

== Zakres testów

Testy obejmują weryfikację:
+ Funkcjonalności sterowania chwytakiem (zakresy kątów, precyzja szerokości)
+ Stabilności komunikacji Bluetooth (utrata pakietów, timeout)
+ Niezawodności systemu (cykle powtarzalne bez błędów)
+ Wydajności (czas transferu, opóźnienie odpowiedzi)

== Test 1: Zakres i precyzja ruchu serwa

=== Cel
Weryfikacja, że serwomechanizm MG996R osiąga wszystkie wymagane pozycje w pełnym zakresie 0°--180° bez skoków ani szumów.

=== Procedura
1. Uruchomić Arduino IDE i otworzyć Serial Monitor (9600 bps)
2. Wysłać komendy `S[kąt]` dla kątów 0, 30, 60, 90, 120, 150, 180 stopni
3. Zaobserwować ruch serwa i odczytać raport pozycji z Serial Monitor
4. Zmierzyć rzeczywisty rozstaw palców suwmiarką dla każdej pozycji

=== Kryteria akceptacji
- Wszystkie pozycje osiągane bez jitteru (drżenia)
- Rozstaw palców zgodny z tabelą kalibracji $±1$ mm
- Czas przejścia między pozycjami $<500$ ms
- Brak błędów UART w Serial Monitor

=== Wyniki (do uzupełnienia po testach)
```
Kąt (°) | Szerokość mierzona (mm) | Szerokość teoretyczna (mm) | Status
--------|--------------------------|----------------------------|--------
  0     |           ?              |          101.0              |
 30     |           ?              |           92.4              |
 60     |           ?              |           83.8              |
 90     |           ?              |           75.2              |
120     |           ?              |           66.6              |
150     |           ?              |           58.0              |
180     |           ?              |           49.4              |
```

== Test 2: Dokładność chwytania

=== Cel
Weryfikacja, że chwytak może precyzyjnie uchwycić obiekty o różnych szerokościach bez upuszczenia.

=== Procedura
1. Przygotować obiekty testowe o szerokościach: 50, 55, 60, 65, 70 mm
2. Dla każdego obiektu:
   - Wysłać komendę `GRAB [szerokość]` z terminala Python
   - Obserwować, czy chwytak prawidłowo chwyta przedmiot
   - Podnieść detal na wysokość 20 cm
   - Zaobserwować, czy detal pozostaje w chwytaku
3. Powtórzyć 10 razy dla każdej szerokości

=== Kryteria akceptacji
- Wszystkie detale chwytnięte bez upuszczenia (80% sukcesów dla każdej szerokości)
- Brak uszkodzeń palców lub detalu
- Łatwe otwieranie palców komendą RELEASE

=== Wyniki (do uzupełnienia)
```
Szerokość (mm) | Chwycenia (10) | Udane (%) | Uwagi
----------------|---|---|---
      50        | ? |   |
      55        | ? |   |
      60        | ? |   |
      65        | ? |   |
      70        | ? |   |
```

== Test 3: Stabilność komunikacji Bluetooth

=== Cel
Weryfikacja, że połączenie Bluetooth jest niezawodne przez 100 cykli bez przerwań lub utraty danych.

=== Procedura
1. Uruchomić terminal Python (`gripper_terminal.py`)
2. Wysłać 100 komend w pętli:
   ```bash
   for i in {1..100}; do
     echo "GRAB 65" >> commands.txt
     echo "RELEASE" >> commands.txt
   done
   ```
3. Zaobserwować, czy wszystkie komendy zostały wykonane bez błędów
4. Zmierzyć czasy odpowiedzi dla każdej komendy

=== Kryteria akceptacji
- 100% niezawodność (brak timeoutów)
- Średni czas odpowiedzi $<250$ ms
- Brak rozłączeń w trakcie testu (pin STATE pozostaje LOW)

=== Wyniki (do uzupełnienia)
```
Test | Liczba komend | Błędy | Średni czas (ms) | Status
-----|---|---|---|---
  1  | 200 |  ? |  ? |
  2  | 200 |  ? |  ? |
  3  | 200 |  ? |  ? |
```

== Test 4: Czas przejścia i wydajność

=== Cel
Zmierzenie czasu wykonania typowych scenariuszy pick-and-place.

=== Procedura
1. Wykonać cykl: ZERO → GRAB 65 → (pauza 1s) → RELEASE
2. Zmierzyć całkowity czas od wysłania pierwszej komendy do potwierdzenia ostatniej
3. Powtórzyć 10 razy i obliczyć średnią

=== Kryteria akceptacji
- Cykl pick-and-place $<2$ sekund (bez pauzy)
- Konsystentność $<±100$ ms między cyklami

=== Wyniki (do uzupełnienia)
```
Cykl | Czas (s) | Notatki
-----|---|---
  1  |   ?   |
  2  |   ?   |
  3  |   ?   |
 ... |   ?   |
 10  |   ?   |
Średnia: ?
```

== Test 5: Bezpieczeństwo --- timeout połączenia

=== Cel
Weryfikacja, że w razie utraty połączenia Bluetooth chwytak powraca do bezpiecznej pozycji.

=== Procedura
1. Wysłać komendę `GRAB 65`
2. Czekać aż chwytak przyjmie pozycję
3. Fizycznie wyłączyć moduł Bluetooth (odłączyć zasilanie lub opuścić zasięg)
4. Zaobserwować, czy chwytak powraca do pozycji bezpiecznej (ZERO)
5. Ponownie sparować i wysłać RELEASE

=== Kryteria akceptacji
- Chwytak nie uszkadza się w wyniku braku zasilania
- Po przywróceniu połączenia system jest gotowy do nowych komend
- Dioda LED miga (brak połączenia)

=== Wyniki (do uzupełnienia)
```
Test | Wynik | Status
-----|---|---
Timeout 1 | Chwytak zwolnił (TAK/NIE) |
Timeout 2 | Możliwość reconnectu (TAK/NIE) |
```

== Test 6: Integracja z UR5e (przyszłość)

=== Cel
Weryfikacja komunikacji między robotem a chwytakiem w warunkach rzeczywistych.

=== Procedura (do opracowania w następnej fazie)
1. Zainstalować bibliotekę `ur_rtde`
2. Uruchomić program synchronizacji robot--chwytak
3. Wykonać 10 cykli pick-and-place w rzeczywistych warunkach
4. Zaobserwować współpracę bez konfliktów czasowych

=== Kryteria akceptacji (do zdefiniowania)
- Wszystkie detale przeniesione bez upuszczenia
- Brak uszkodzeń robota lub chwytaka
- Czas cyklu $<5$ sekund (z transportem)

== Raport końcowy

Po ukończeniu wszystkich testów należy:
1. Zebrać wyniki w tabeli porównawczej
2. Zidentyfikować wszelkie anomalie lub obszary do poprawy
3. Dokumentować wszelkie modyfikacje kodu, które były konieczne
4. Sformułować wnioski dotyczące przydatności rozwiązania do zautomatyzowanego procesu pick-and-place
