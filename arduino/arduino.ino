#include <PWMServo.h>
#include <SoftwareSerial.h>

SoftwareSerial bluetooth(2, 3);   // RX, TX
PWMServo chwytakServo;

const int servoPin = 10;
const int pinLeda = 13;

// Zakres pracy serwa
const int KAT_ZAMKNIETY = 70;
const int KAT_OTWARTY   = 140;

// Kalibracja mechaniczna
const float ROZSTAW_PRZY_70  = 51.0;  // mm
const float ROZSTAW_PRZY_140 = 71.0;  // mm

// Luz dociśnięcia
const float MARGINES_CHWYTU = 0.0;

int aktualnyKat = KAT_OTWARTY;
float szerokoscPrzedmiotu = 63.0;

void wyslijWiadomosc(String tekst) {
  Serial.println(tekst);
  bluetooth.println(tekst);
}

void wypiszMenu() {
  wyslijWiadomosc("--- Chwytak ---");
  wyslijWiadomosc("ZERO");
  wyslijWiadomosc("WIDTH 65");
  wyslijWiadomosc("GRAB");
  wyslijWiadomosc("GRAB 65");
  wyslijWiadomosc("RELEASE");
  wyslijWiadomosc("STATUS");
  wyslijWiadomosc("----------------");
}

void ustawKat(int nowyKat) {
  if (nowyKat > KAT_OTWARTY) nowyKat = KAT_OTWARTY;
  if (nowyKat < KAT_ZAMKNIETY) nowyKat = KAT_ZAMKNIETY;

  digitalWrite(pinLeda, HIGH);

  if (aktualnyKat < nowyKat) {
    for (int i = aktualnyKat; i <= nowyKat; i++) {
      chwytakServo.write(i);
      delay(10);
    }
  } else {
    for (int i = aktualnyKat; i >= nowyKat; i--) {
      chwytakServo.write(i);
      delay(10);
    }
  }

  aktualnyKat = nowyKat;

  digitalWrite(pinLeda, LOW);
}

int szerokoscNaKat(float szerokoscMm) {
  if (szerokoscMm < ROZSTAW_PRZY_70) szerokoscMm = ROZSTAW_PRZY_70;
  if (szerokoscMm > ROZSTAW_PRZY_140) szerokoscMm = ROZSTAW_PRZY_140;

  float zakresRozstawu = ROZSTAW_PRZY_140 - ROZSTAW_PRZY_70;
  float zakresKata = KAT_OTWARTY - KAT_ZAMKNIETY;

  float wspolczynnik = (szerokoscMm - ROZSTAW_PRZY_70) / zakresRozstawu;
  int kat = KAT_ZAMKNIETY + round(wspolczynnik * zakresKata);

  if (kat > KAT_OTWARTY) kat = KAT_OTWARTY;
  if (kat < KAT_ZAMKNIETY) kat = KAT_ZAMKNIETY;

  return kat;
}

void zero() {
  ustawKat(KAT_OTWARTY);
  wyslijWiadomosc("OK ZERO -> 140");
}

void releaseObject() {
  int nowyKat = aktualnyKat + 20;
  if (nowyKat > KAT_OTWARTY) nowyKat = KAT_OTWARTY;

  ustawKat(nowyKat);
  wyslijWiadomosc("OK RELEASE -> " + String(aktualnyKat));
}

void setWidth(float szerokoscMm) {
  szerokoscPrzedmiotu = szerokoscMm;
  wyslijWiadomosc("OK WIDTH = " + String(szerokoscPrzedmiotu, 1) + " mm");
}

void grab(float szerokoscMm) {
  szerokoscPrzedmiotu = szerokoscMm;

  float docelowyRozstaw = szerokoscPrzedmiotu + MARGINES_CHWYTU;

  if (docelowyRozstaw < ROZSTAW_PRZY_70) docelowyRozstaw = ROZSTAW_PRZY_70;
  if (docelowyRozstaw > ROZSTAW_PRZY_140) docelowyRozstaw = ROZSTAW_PRZY_140;

  int docelowyKat = szerokoscNaKat(docelowyRozstaw);
  ustawKat(docelowyKat);

  wyslijWiadomosc("OK GRAB width=" + String(szerokoscPrzedmiotu, 1) +
                  " gap=" + String(docelowyRozstaw, 1) +
                  " angle=" + String(aktualnyKat));
}

void status() {
  wyslijWiadomosc("STATUS angle=" + String(aktualnyKat) +
                  " width=" + String(szerokoscPrzedmiotu, 1) +
                  " servo_range=70-140");
}

float pobierzLiczbeZKomendy(String komenda) {
  komenda.trim();

  int spacja = komenda.indexOf(' ');
  if (spacja < 0) spacja = komenda.indexOf('=');
  if (spacja < 0) return NAN;

  String liczba = komenda.substring(spacja + 1);
  liczba.trim();
  return liczba.toFloat();
}

void obsluzKomende(String komenda) {
  komenda.trim();
  if (komenda.length() == 0) return;

  String upper = komenda;
  upper.toUpperCase();

  if (upper == "ZERO") {
    zero();
  }
  else if (upper == "RELEASE") {
    releaseObject();
  }
  else if (upper == "STATUS") {
    status();
  }
  else if (upper.startsWith("WIDTH")) {
    float w = pobierzLiczbeZKomendy(komenda);
    if (isnan(w)) {
      wyslijWiadomosc("ERR WIDTH requires number, e.g. WIDTH 65");
      return;
    }
    setWidth(w);
  }
  else if (upper.startsWith("GRAB")) {
    float w = pobierzLiczbeZKomendy(komenda);
    if (isnan(w)) {
      grab(szerokoscPrzedmiotu);   // użyj zapisanej szerokości
    } else {
      grab(w);                     // ustaw i od razu chwyć
    }
  }
  else {
    wyslijWiadomosc("ERR Unknown command");
  }
}

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);

  pinMode(pinLeda, OUTPUT);
  digitalWrite(pinLeda, LOW);

  chwytakServo.attach(servoPin);
  chwytakServo.write(aktualnyKat);

  wyslijWiadomosc("POWER ON");
  wyslijWiadomosc("READY");
  wypiszMenu();
  status();
}

void loop() {
  String komenda = "";

  if (bluetooth.available() > 0) {
    komenda = bluetooth.readStringUntil('\n');
    if (komenda.length() > 0) {
      wyslijWiadomosc("BT CMD: " + komenda);
      obsluzKomende(komenda);
    }
  }
  else if (Serial.available() > 0) {
    komenda = Serial.readStringUntil('\n');
    if (komenda.length() > 0) {
      wyslijWiadomosc("USB CMD: " + komenda);
      obsluzKomende(komenda);
    }
  }
}