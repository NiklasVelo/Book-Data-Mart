# Buchtausch App
## Konzeptionsphase

---

## 1. Problembeschreibung und Zielsetzung

Viele Bücher werden nach dem Lesen nicht mehr genutzt, obwohl andere Personen genau diese Titel suchen. Eine Buchtausch App schafft hier eine einfache Lösung: Nutzer können eigene Bücher zum Ausleihen anbieten und Bücher von anderen ausleihen, ohne sie kaufen zu müssen.

Ziel dieser Datenbankentwicklung ist die vollständige, **normalisierte** Speicherung aller relevanten Daten — von Buchmetadaten über Nutzeradressen bis hin zu Ausleihtransaktionen und Übergabeterminen.

---

## 2. Anforderungen

### 2.1 Benutzermodell

Die App verwendet ein **offenes Benutzermodell** ohne feste Rollentrennung. Jede registrierte Person kann gleichzeitig Bücher anbieten und ausleihen — eine explizite Unterscheidung zwischen „Verleiher:in" und „Ausleiher:in" existiert auf Datenbankebene nicht. Alle Aktionen sind an den allgemeinen Nutzeraccount (`users`) gebunden.

| Nutzertyp | Beschreibung |
|---|---|
| **User** | Kann eigene Buchexemplare anbieten, Zeitslots erstellen, Bücher suchen und ausleihen — gleichzeitig und ohne Rollenwechsel. |

### 2.2 Aktionen eines registrierten Users

**Zum Verleihen:**
- Buchexemplar mit Metadaten und Zustand einstellen
- Eigene Adressen hinterlegen
- Zeitslots für Buch-Übergaben anlegen (mit Treffpunkt Adresse und Zeitfenster)

**Zum Ausleihen:**
- Verfügbare Bücher nach Titel, Genre, Autor, Stadt oder GPS-Koordinaten suchen
- Buchexemplare mit verfügbaren Zeitslots und Treffpunkt Adressen einsehen
- Sich für einen Zeitslot anmelden und ein Buchexemplar reservieren
- Buch fristgerecht zurückgeben

### 2.3 Vorerst Benötigte Daten

**Bücher:**
- Titel, ISBN, Erscheinungsjahr, Sprache
- Autor:in(nen) – mehrere möglich (M:N)
- Verlag
- Genre(s) – mehrere möglich (M:N)

**Buchexemplar / Angebot (book_listings):**
- Exemplar mit Zustand (`Neu`, `Sehr gut`, `Gut`, `Akzeptabel`, `Schlecht`)
- Maximale Leihdauer in Tagen
- Verfügbarkeitsstatus
- Notizen des Verleihers

**Zeitfenster (meeting_slots):**
- Datum, Uhrzeit von/bis für Buch-Übergaben (Für Abholung und Rückgabe)
- Treffpunkt Adresse direkt am Slot
- Maximale Teilnehmerzahl pro Slot

**Benutzer:**
- Name, E-Mail, Telefon
- Eine oder mehrere Adressen mit GPS-Koordinaten
- Registrierungsdatum

**Slot-Anmeldung (slot_signups):**
- Verknüpfung: User + Zeitfenster
- Bei Abholungen: `listing_id` gibt das reservierte Exemplar an
- Bei Rückgaben: `listing_id` ist NULL (Slots können sowohl für Abholung als auch Rückgabe genutzt werden)
- UNIQUE-Constraint auf `listing_id` verhindert Doppel Reservierungen daher nach Rückgabe -> `slot_signups` Eintrag löschen

**Ausleihen (loans):**
- Verknüpfung: Ausleiher + Buchexemplar + Abholslot (Dreifachbeziehung)
- Ausleihdatum, Fälligkeitsdatum, tatsächliches Rückgabedatum
- Status wird aus Datenlage abgeleitet: `return_date IS NULL` = aktiv; `due_date < heute AND return_date IS NULL` = überfällig; `return_date IS NOT NULL` = zurückgegeben

---

## 3. Lösungskonzept

Das Datenbankschema wird **relational** und nach der **dritten Normalform** entworfen, um Redundanzen zu eliminieren.

- **Trennung von Buch und Exemplar**: `books` enthält unveränderliche Metadaten; `book_listings` repräsentiert ein verleihbares Exemplar.
- **Normalisierung von Autoren und Genres**: M:N-Beziehungen mit Verbindungstabellen `book_authors` und `book_genres` Verbinden.
- **GPS-basierte Suche**: Adressen speichern `latitude` und `longitude`. Erlaubt sowohl für Stadt basierte als auch Geo basierte Suchen.
- **Zeitslot-System**: `meeting_slots` sind zeitfenster die ein User anlegen kann, welchen andere Nutzer für Abholung oder Rückgabe buchen können. Slots haben eine Adresse, die den Treffpunkt zu dem bestimmten Zeitslot angibt.
- **Adresse am Slot**: Die Treffpunkt-Adresse hängt an `meeting_slots.address_id`, nicht am Buchexemplar oder Verleiher, da der Übergabeort eine Eigenschaft des Treffen ist.
- **Dreifachbeziehungen** (2 Stück):
  1. `slot_signups` = User x MeetingSlot x BookListing (Bei Anmeldung zum ausleihen, ansonsten eine Binärbeziehung, da für Rückgabe `listing_id` nicht zum reservieren eines Exemplars gebraucht wird)
  2. `loans` = Ausleiher x BookListing x MeetingSlot (Ausleihtransaktion)

**Gewähltes Database Management System (DBMS):** PostgreSQL 15+ (freie Open-Source-Lösung, robuste SQL-Unterstützung, sauber normalisierbar)

## 4. Datenbankstruktur Entity Relationship Modell

*Kommt Bald*