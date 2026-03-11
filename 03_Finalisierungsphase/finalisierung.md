# Buchtausch-App  Abschlussdokumentation
### Portfoliokurs DLBDSPBDM01 | IU Internationale Hochschule
### Finalisierungsphase

---

## 1. Systembeschreibung und Funktionalität

Die entwickelte Datenbank bildet das Rückgrat einer Buchtausch-App, die es Mitgliedern einer lokalen Gemeinschaft ermöglicht, Bücher gegenseitig auszuleihen. Das System wurde als relationale PostgreSQL-Datenbank in der dritten Normalform (3NF) implementiert.

### Kernfunktionen

**Buchverwaltung:** Die Datenbank trennt zwischen dem abstrakten Buch (Tabelle `books` mit ISBN, Titel, Autor, Verlag, Genre, Erscheinungsjahr und Sprache) und dem konkreten Exemplar, das ein User anbietet (Tabelle `book_listings` mit Zustand, Leihdauer und Verfügbarkeitsstatus). Diese Trennung erlaubt es mehreren Benutzenden, dasselbe Werk anzubieten.

**Benutzerverwaltung:** Benutzende (`users`) besitzen eine oder mehrere Adressen (`addresses`), die über `postal_codes` mit PLZ und Stadt normalisiert verknüpft sind. Jede Person kann gleichzeitig als Verleiher und Ausleiher agieren.

**Zeitslot-System:** Benutzende bieten Übergabefenster in Form von `meeting_slots` an. Jeder Slot ist einer konkreten Adresse zugewiesen  damit ist der Treffpunkt eine Eigenschaft des Termins, nicht des Buches. Dasselbe Slot-System dient sowohl für Abholungen als auch Rückgaben.

**Reservierung und Doppelbuchungsschutz:** Die Tabelle `slot_signups` ist eine assoziative Entität, die Users mit Slots und optional mit einem Buchexemplar verbindet. Der `UNIQUE`-Constraint auf `listing_id` verhindert technisch, dass ein Buch doppelt reserviert werden kann. Nach Rückgabe wird der Abholungs-Signup gelöscht, sodass das Exemplar erneut ausleihbar ist.

**Ausleihtransaktionen:** `loans` erfasst die vollständige Dreifachbeziehung aus Ausleiher, Buchexemplar und Abholslot. Fälligkeitsdatum und Rückgabedatum ermöglichen die Berechnung des Leihstatus (`aktiv`, `überfällig`, `zurückgegeben`) als abgeleitetes Attribut per SQL-`CASE`-Ausdruck.

---

## 2. Datenbankstruktur und Metadaten

### 2.1 Tabellenübersicht

| Tabelle | Einträge | Beschreibung |
|---|---|---|
| `users` | 12 | Registrierte Benutzende |
| `postal_codes` | 10 | PLZ-Stadt-Zuordnungen |
| `addresses` | 12 | Wohnadressen der Benutzenden |
| `publishers` | 10 | Buchverlage |
| `authors` | 11 | Buchautoren |
| `genres` | 10 | Buchgenres |
| `books` | 12 | Buchtitel im Katalog |
| `book_authors` | 12 | Verknüpfungen Buch  Autor |
| `book_genres` | 19 | Verknüpfungen Buch  Genre |
| `book_listings` | 12 | Buchexemplare zum Verleih |
| `meeting_slots` | 16 | Übergabezeitfenster |
| `slot_signups` | 10 | Aktive Slot-Anmeldungen |
| `loans` | 10 | Ausleihtransaktionen |
| **Gesamt** | **146** | |

> Die Einträge in `slot_signups` variieren dynamisch, da abgeschlossene Abholungs-Signups nach Rückgabe gelöscht werden.

### 2.2 Indizes

| Index | Tabelle | Spalte | Zweck |
|---|---|---|---|
| `idx_users_email` | `users` | `email` | Schnelles Login-Lookup |
| `idx_books_title` | `books` | `title` | Titelsuche mit ILIKE |
| `idx_loans_borrower` | `loans` | `borrower_id` | Alle Ausleihen eines Users |
| `idx_loans_active` | `loans` | `return_date WHERE NULL` | Aktive Ausleihen (partiell) |
| *(auto)* | `slot_signups` | `UNIQUE(listing_id)` | Doppelbuchungsschutz |
| *(auto)* | `slot_signups` | `UNIQUE(slot_id, user_id)` | Doppel-Anmeldung verhindern |

### 2.3 Datenbankgröße

> **Hinweis:** Die folgenden Werte werden nach dem Laden der Datenbank mit dem Befehl gemessen:
> ```sql
> SELECT pg_size_pretty(pg_database_size('buchtausch_db')) AS datenbankgröße;
> ```
> Typischer Wert mit Testdaten: ca. **810 MB** (inkl. Systemkatalog und Indizes).

---

## 3. Designentscheidungen und Normalisierung

### 3NF-Normalisierung

Das Schema entspricht der dritten Normalform:

- **1NF**: Alle Attribute sind atomar. Mehrfachwertige Abhängigkeiten (Autoren, Genres) wurden in separate Tabellen (`book_authors`, `book_genres`) ausgelagert.
- **2NF**: In `book_authors` und `book_genres` (zusammengesetzte Primärschlüssel) hängen alle Attribute vollständig vom Gesamtschlüssel ab.
- **3NF**: Transitive Abhängigkeit `PLZ  Stadt` wurde durch Auslagerung in `postal_codes` eliminiert.

### Zentrale Designentscheidungen

**Adresse am Slot, nicht am Listing:** Die Treffpunkt-Adresse ist einer Eigenschaft des Übergabetermins, nicht des Buchexemplars. Ein Verleiher kann verschiedene Slots an verschiedenen Orten anbieten  etwa einen Slot an der Arbeit und einen zuhause. Dies wird durch `meeting_slots.address_id` korrekt abgebildet.

**Status nicht gespeichert:** `loans.status` wird nicht als Attribut gespeichert, sondern per `CASE`-Ausdruck aus `due_date` und `return_date` abgeleitet. Dies vermeidet Inkonsistenzen und ist semantisch korrekt.

**Einfache Standortsuche:** Statt GPS-Koordinaten und einer räumlichen Extension (PostGIS) wird die Suche auf Stadtebene über `postal_codes.city` realisiert. Dies ist für eine Community-App ausreichend und vermeidet unnötige Komplexität.

**Lifecycle von `slot_signups`:** Ein Pickup-Signup hat seinen Zweck erfüllt, sobald das Buch abgeholt wurde. Nach Rückgabe wird er gelöscht: `UNIQUE(listing_id)` wird freigegeben und das Exemplar kann erneut reserviert werden.

---

### GitHub Repository

[Github Repository des Projekts](<https://github.com/NiklasVelo/Book-Data-Mart>)

---