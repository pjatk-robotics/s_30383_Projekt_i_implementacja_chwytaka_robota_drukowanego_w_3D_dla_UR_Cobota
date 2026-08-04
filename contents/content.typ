= Implementacja i wyniki

W tym rozdziale opisano właściwą realizację projektu: od modelu CAD, przez proces druku, aż po uruchomienie na stanowisku z robotem.

== Projekt mechaniczny chwytaka

Chwytak zaprojektowano jako konstrukcję dwupalcową. Model CAD opracowano w środowisku Fusion, a cały proces projektowy rozpoczęto od analizy geometrii detalu oraz wyznaczenia stref kontaktu palców. Na tej podstawie przygotowano model 3D korpusu, palców i elementów mocujących z uwzględnieniem:
- kierunków przenoszenia obciążeń,
- miejsc mocowania do adaptera robota,
- możliwości szybkiej wymiany elementów kontaktowych,
- minimalizacji masy przy zachowaniu sztywności.
Poniższe ilustracje przedstawiają widoki modelu chwytaka opracowanego w Fusion i dokumentują finalną geometrię: pełny zespół, bazę główną oraz zestaw palców.
#figure(
  caption: [Widok ogólny modelu chwytaka -- ujęcie 1 (całość zespołu).]
)[
  #image("assets/images/model/all1.png", width: 85%)
]
#figure(
  caption: [Widok ogólny modelu chwytaka -- ujęcie 2 (całość zespołu).]
)[
  #image("assets/images/model/all2.png", width: 85%)
]
#figure(
  caption: [Widok ogólny modelu chwytaka -- ujęcie 3 (całość zespołu).]
)[
  #image("assets/images/model/all3.png", width: 85%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok z przodu.]
)[
  #image("assets/images/model/mainFront.png", width: 70%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok z prawej strony.]
)[
  #image("assets/images/model/mainRight.png", width: 70%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok z tyłu.]
)[
  #image("assets/images/model/mainBack.png", width: 70%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok z lewej strony.]
)[
  #image("assets/images/model/mainLeft.png", width: 70%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok z góry.]
)[
  #image("assets/images/model/mainUp.png", width: 70%)
]
#figure(
  caption: [Baza chwytaka (main) -- widok od dołu.]
)[
  #image("assets/images/model/mainBot.png", width: 70%)
]
#figure(
  caption: [Palce chwytaka -- widok 1.]
)[
  #image("assets/images/model/fingers1.png", width: 80%)
]
#figure(
  caption: [Palce chwytaka -- widok 2.]
)[
  #image("assets/images/model/fingers2.png", width: 80%)
]
#figure(
  caption: [Palce chwytaka -- widok 3.]
)[
  #image("assets/images/model/fingers3.png", width: 80%)
]
#figure(
  caption: [Palce chwytaka -- widok 4.]
)[
  #image("assets/images/model/fingers4.png", width: 80%)
]
Geometria robocza chwytaka została dobrana do przedmiotów o szerokości od 63 mm do 73 mm. W praktyce oznacza to możliwość chwytania różnych obiektów cylindrycznych i zbliżonych kształtem, takich jak aluminiowe puszki napojów 500 ml, stalowe puszki oraz inne elementy mieszczące się w tym zakresie wymiarowym.