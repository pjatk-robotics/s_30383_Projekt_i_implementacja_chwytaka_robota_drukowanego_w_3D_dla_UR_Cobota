#import "pjatk-template.typ": apply-pjatk-template
#show: apply-pjatk-template.with(
  language: "pl",
  thesis-type: "engineering",
  faculty: "Wydział Informatyki",
  department: "Katedra Mechaniki, Informatyki i Robotyki",
  specialization: "Robotyka i Inteligentne Systemy Autonomiczne",
  field-of-study: "Informatyka",
  authors: ("Radosław Kiełt --- s30383",),
  title: "Projekt i implementacja chwytaka robota drukowanego w 3D dla UR Cobota",
  supervisor: "Julia Wiśniewska",
  supervisor-pl: "Julia Wiśniewska",
  reviewer: "Imię i nazwisko recenzenta",
  abstract: [
    Praca przedstawia proces zaprojektowania, wykonania i uruchomienia dwupalcowego chwytaka do robota UR Cobot. Model mechaniczny opracowano w środowisku Fusion, a obudowę oraz palce wykonano metodą druku 3D. W konstrukcji wykorzystano serwomechanizm MG996R, moduł Nano SuperMini V3 (ATmega328P, zgodny z Arduino), moduł Bluetooth klasy HC-05/HC-06, przetwornicę step-down LM2596 oraz zasilanie z dwóch akumulatorów 18650. Celem projektu było uzyskanie taniego i łatwo modyfikowalnego chwytaka do zadań pick-and-place oraz weryfikacja działania prototypu w warunkach stanowiskowych.
  ],
  keywords: [chwytak dwupalcowy #sym.dot.op UR Cobot #sym.dot.op Fusion #sym.dot.op druk 3D #sym.dot.op MG996R],
)

#include "contents/introduction.typ"

#include "contents/context.typ"

#include "contents/functional-requirements.typ"

#include "contents/non-functional-requirements.typ"

#include "contents/use-cases.typ"

#include "contents/content.typ"

#include "contents/ai-report.typ"
