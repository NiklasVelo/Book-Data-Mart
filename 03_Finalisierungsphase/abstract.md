# Abstract - Buchtausch App Datenbankprojekt

---

## Problemstellung und Zielsetzung

Viele Bücher stehen nach dem Lesen ungenutzt im Regal, während andere Personen genau diese Titel suchen. Eine Buchtausch-App löst dieses Problem: Nutzer können Buchexemplare anbieten und von anderen ausleihen. 

Ziel dieses Projekts war die Entwicklung einer vollständig normalisierten relationalen Datenbank, die alle dafür notwendigen Daten speichert und verwaltet.

---

## Konzeptioneller Lösungsansatz

Das Schema wurde nach der dritten Normalform entworfen. Eine zentrale Entscheidung war die Trennung zwischen dem abstrakten Buch als Katalogeintrag und dem konkreten verleihbaren Exemplar — derselbe Titel kann von mehreren Nutzern angeboten werden, ohne Daten zu duplizieren.

Das Zeitslot-System ist als eigenständige Entität konzipiert: Übergabezeitfenster sind an Nutzende mit einer Adresse pro Slot gebunden, nicht an einzelne Bücher. Damit kann ein Verleiher mehrere Bücher im selben Termin übergeben, und ein Ausleiher kann mehrere Bücher in einem Slot abholen oder zurückgeben.

Zwei Dreifachbeziehungen bilden die zentralen Abläufe ab: `slot_signups` verknüpft User, Zeitfenster und Buchexemplar für Reservierungen; `loans` verbindet Ausleiher, Buchexemplar und Abholslot für das Ausleihen.

---

## Technische Umsetzung

**DBMS:** PostgreSQL. Eine freie Open-Source Lösung mit Unterstützung für `CHECK`-Constraints und `ON DELETE CASCADE/RESTRICT`.

**Testdaten:** 12 Nutzer, 12 Bücher, 16 Zeitslots und 10 Ausleihen. Aktive, überfällige und zurückgegebene Ausleihen sind abgedeckt.

**Dokumentation:** `walkthrough.sql` simuliert eine vollständige Interaktion in 11 Schritten; `queries.sql` enthält 21 kommentierte Abfrage- und Eingabe-Vorlagen für den realen Betrieb.


> [Github Repository des Projekts](<https://github.com/NiklasVelo/Book-Data-Mart>)