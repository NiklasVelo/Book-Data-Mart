# Setup – Buchtausch App Datenbank

## Voraussetzungen

- [PostgreSQL](https://www.postgresql.org/download/) installiert und gestartet (beinhaltet unteranderem: pgAdmin 4 und SQL Shell)

---

## Option A – SQL Shell (psql)

### 1. SQL Shell öffnen

**SQL Shell (psql)** starten. Die Verbindungsabfragen (Server, Port, Datenbank, Benutzer) mit **Enter** bestätigen, dann das bei der Installation vergebene Passwort eingeben.

> **Hinweis:** Bei der Passworteingabe erscheinen keine Zeichen beim Tippen. Das ist beabsichtigt. Passwort einfach blind eintippen und mit **Enter** bestätigen.

### 2. Datenbank anlegen

```sql
CREATE DATABASE buchtausch_db;
```

### 3. Zur neuen Datenbank wechseln

```sql
\c buchtausch_db
```

### 4. Schema und Testdaten importieren

```sql
\i '<Dateipfad>/02_Erarbeitungs-Reflexionsphase/buchtausch_app.sql'
```

> **Hinweis:** Für `<Dateipfad>` den tatsächlichen Pfad auf dem Computer mit Schrägstrichen angeben (keine Backslashes). Beispiel: `C:/Users/Username/Documents/buchtausch_app.sql`

### 5. Interaktionsbeispiel ausführen (optional)

```sql
\i '<Dateipfad>/02_Erarbeitungs-Reflexionsphase/walkthrough.sql'
```

### 6. Datenbank erkunden

SQL Queries in der Shell eingeben. Nützliche Abfragen sind in `queries.sql` zu finden.

---

## Option B – pgAdmin 4 (Visuelle Oberfläche)

### 1. pgAdmin 4 öffnen

**pgAdmin 4** starten.

### 2. Datenbank anlegen

In der linken Anzeige: 
1. Servers **Doppelklicken** und Passwort für den PostgreSQL Benutzer eingeben (Normalerweise bei der Installation vergeben) 
2. Rechtsclick auf einen Server (z.B. `PostgreSQL 18`) -> **Create -> Database...**
3. Name: `buchtausch_db` eingeben -> **Save** klicken

### 3. Schema und Testdaten importieren

Databases aufklappen -> Rechtsklick auf `buchtausch_db` -> **Query Tool** öffnen.

Oben das **Ordner Symbol** klicken -> `buchtausch_app.sql` auswählen (unter `02_Erarbeitungs-Reflexionsphase/`) -> **Execute Script** Symbol klicken oder **F5** drücken.

### 4. Interaktionsbeispiel ausführen (optional)

Gleich wie Schritt 3, aber `walkthrough.sql` auswählen.

### 5. Datenbank erkunden

Im linken Baum: **buchtausch_db -> Schemas -> public -> Tables**

Rechtsklick auf eine Tabelle → **View/Edit Data -> First 100 Rows** um die Testdaten zu sehen.
Oder im Query Tool SQL-Abfragen eingeben. Nützliche Abfragen sind in `queries.sql` zu finden.


