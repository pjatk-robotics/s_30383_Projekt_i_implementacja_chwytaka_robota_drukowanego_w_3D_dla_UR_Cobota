= Wymagania funkcjonalne

Wymagania funkcjonalne opisują, co chwytak i stanowisko z robotem mają realizować z perspektywy użytkownika procesu.

== Lista wymagań

- Chwytak musi realizować chwyt dwoma palcami napędzanymi jednym serwomechanizmem.
- Chwytak musi umożliwiać stabilne pobranie detalu z pozycji odkładczej.
- Chwytak musi utrzymywać detal podczas transportu po zadanej trajektorii robota.
- Chwytak musi umożliwiać odkładanie detalu z powtarzalnością pozycji wystarczającą dla procesu.
- Konstrukcja musi umożliwiać szybki demontaż i wymianę elementów kontaktowych z detalem.
- Rozwiązanie musi pozwalać na korektę geometrii szczęk bez przebudowy całego chwytaka.
- Układ musi współpracować z programem robota realizującym sekwencję pick-and-place.
- Układ sterowania musi umożliwiać zdalne uruchomienie lub konfigurację przez interfejs Bluetooth.
- Chwytak musi raportować status aktualnej pozycji palców i stanu połączenia.
- System musi logować połączenia i rozłączenia Bluetooth dla celów diagnostycznych.
- Chwytak musi sygnalizować wizualnie stan systemu (dioda LED: połączenie, wykonywanie zadania, błąd).
- Mikrokontroler musi obsługiwać timeout połączenia i automatycznie powracać do pozycji bezpiecznej w razie utraty komunikacji.

== Kryteria akceptacji

Wymagania uznaje się za spełnione, jeżeli chwytak poprawnie realizuje cykl pobranie--transport--odłożenie w serii testowej bez utraty detalu i bez uszkodzeń elementów konstrukcyjnych.