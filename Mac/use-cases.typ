= Przypadki użycia

W rozdziale przedstawiono kluczowe interakcje operatora z systemem chwytaka.

== UC-01: Pobranie i odłożenie detalu

*Aktor główny:* Operator stanowiska.

*Warunek początkowy:* Robot w pozycji bazowej, detal dostępny w strefie pobrania, chwytak zasilony.

*Scenariusz podstawowy:*
1. Operator uruchamia program cyklu pick-and-place.
2. Robot przemieszcza chwytak nad detal.
3. Mikrokontroler wysyła sygnał do serwomechanizmu MG996R --- palce zamykają się na detalu.
4. Robot transportuje detal do pozycji odkładczej.
5. Mikrokontroler otwiera palce --- detal zostaje odłożony.
6. Robot powraca do pozycji bazowej.

*Rezultat:* Detal przeniesiony poprawnie, bez upuszczenia i uszkodzeń.

== UC-02: Zdalne sterowanie chwytakiem przez Bluetooth

*Aktor główny:* Operator.

*Warunek początkowy:* Chwytak zasilony, moduł Bluetooth sparowany z urządzeniem operatora.

*Scenariusz podstawowy:*
1. Operator wysyła komendę otwarcia/zamknięcia palców z urządzenia mobilnego lub komputera.
2. Moduł Bluetooth przekazuje komendę do ATmega328P.
3. Mikrokontroler ustawia odpowiednią pozycję serwomechanizmu.
4. Palce przyjmują zadaną pozycję.

*Rezultat:* Chwytak odpowiada na polecenia bez konieczności fizycznego dostępu do stanowiska.

== UC-03: Uruchomienie stanowiska

*Aktor główny:* Operator.

*Warunek początkowy:* Akumulatory 18650 naładowane, chwytak zamontowany na robocie.

*Scenariusz podstawowy:*
1. Operator załącza zasilanie akumulatorowe.
2. Przetwornica LM2596 dostarcza właściwe napięcie do elektroniki.
3. Mikrokontroler inicjalizuje się i ustawia serwomechanizm w pozycję spoczynkową (palce otwarte).
4. Moduł Bluetooth zgłasza gotowość do parowania.
5. Operator weryfikuje poprawność działania ruchem testowym.

*Rezultat:* Stanowisko gotowe do pracy.

== UC-04: Wyłączenie i odłożenie stanowiska

*Aktor główny:* Operator.

*Warunek początkowy:* Cykl roboczy zakończony, robot w pozycji bazowej.

*Scenariusz podstawowy:*
1. Operator wydaje komendę otwarcia palców (chwytak pusty).
2. Operator odłącza zasilanie akumulatorowe.
3. Serwomechanizm zatrzymuje się w ostatniej pozycji.

*Rezultat:* Chwytak bezpiecznie wyłączony, gotowy do kolejnego uruchomienia.

== Zastosowanie chwytaka do różnych przedmiotów

Chwytak może być wykorzystywany do pobierania i odkładania przedmiotów mieszczących się w zakresie roboczym 63--73 mm, w szczególności aluminiowych puszek napojów 500 ml, stalowych puszek oraz innych detali o zbliżonej geometrii. W kodzie sterującym warto przewidzieć parametr szerokości przedmiotu, na podstawie którego wyznaczana będzie pozycja zacisku serwomechanizmu.

Takie rozwiązanie pozwala zachować prostą logikę sterowania przy jednoczesnej możliwości obsługi kilku typów obiektów bez mechanicznej przebudowy chwytaka.