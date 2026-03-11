-- =============================================================================
-- Buchtausch App Datenbank
-- Datenbank System: PostgreSQL
--
-- Relationale Datenbank für eine Buchtausch-App,
-- die das Ausleihen und Zurückgeben von Büchern ermöglicht.
-- 
-- Diese Datei auf einen PostgreSQL Server laden, um die Datenbank mit Tabellen und Testdaten zu initialisieren.
--
-- TABELLEN-ÜBERSICHT (13 Tabellen):
--   1.  users              Registrierte Benutzer
--   2.  postal_codes       PLZ-Stadt-Zuordnung
--   3.  addresses          Adressen
--   4.  publishers         Verlage
--   5.  authors            Autoren
--   6.  genres             Buchgenres
--   7.  books              Bücher
--   8.  book_authors       M:N Bücher <-> Autoren
--   9.  book_genres        M:N Bücher <-> Genres
--   10. book_listings      Angebot eines Buchexemplars zum Ausleihen
--   11. meeting_slots      Zeitfenster eines Users für Buch Übergaben (Abholung/Rückgabe)
--   12. slot_signups       M:N Anmeldungen zu einem Zeitslot eines anderen Users
--   13. loans              Ausleihtransaktionen (Dreifachbeziehung 2 mit users + book_listings + meeting_slots)
-- =============================================================================


-- Bestehende Tabellen löschen (falls vorhanden) –> CASCADE löscht abhängige Objekte automatisch
DROP TABLE IF EXISTS loans           CASCADE;
DROP TABLE IF EXISTS slot_signups    CASCADE;
DROP TABLE IF EXISTS meeting_slots   CASCADE;
DROP TABLE IF EXISTS book_listings   CASCADE;
DROP TABLE IF EXISTS book_genres     CASCADE;
DROP TABLE IF EXISTS book_authors    CASCADE;
DROP TABLE IF EXISTS books           CASCADE;
DROP TABLE IF EXISTS genres          CASCADE;
DROP TABLE IF EXISTS authors         CASCADE;
DROP TABLE IF EXISTS publishers      CASCADE;
DROP TABLE IF EXISTS addresses       CASCADE;
DROP TABLE IF EXISTS postal_codes    CASCADE;
DROP TABLE IF EXISTS users           CASCADE;


-- =============================================================================
-- TABELLE 1: users
-- Speichert alle registrierten Benutzenden der App.
-- Jede Person kann gleichzeitig Verleiher und Ausleiher sein, daher keine
-- Unterscheidung in separate Tabellen.
-- =============================================================================
CREATE TABLE users (
    user_id    SERIAL       PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    phone      VARCHAR(30),
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email); --Email als Index, häufig für schnellere anmeldungssuche verwendet


-- =============================================================================
-- TABELLE 2: postal_codes
-- PLZ-Stadt-Zuordnung. Ausgelagert aus addresses für Normalisierung
-- --> Stadt Name nicht abhängig von der adress_id, sondern von der PLZ.
-- =============================================================================
CREATE TABLE postal_codes (
    postal_code_id SERIAL       PRIMARY KEY,
    postal_code    VARCHAR(20)  NOT NULL UNIQUE,
    city           VARCHAR(100) NOT NULL
);


-- =============================================================================
-- TABELLE 3: addresses
-- Speichert Adressen der User.
-- Anmerkung: Ein User kann mehrere Adressen haben (z.B. Wohnort + Ferienwohnung),
-- =============================================================================
CREATE TABLE addresses (
    address_id     SERIAL         PRIMARY KEY,
    user_id        INT            NOT NULL REFERENCES users(user_id)               ON DELETE CASCADE,
    postal_code_id INT            NOT NULL REFERENCES postal_codes(postal_code_id) ON DELETE RESTRICT,
    street         VARCHAR(200)   NOT NULL,
    house_number   VARCHAR(10)    NOT NULL,
    country        VARCHAR(100)   NOT NULL DEFAULT 'Deutschland',
    latitude       DECIMAL(9,6),  -- GPS-Koordinate (WGS84), für räumliche Suche
    longitude      DECIMAL(9,6)   -- GPS-Koordinate (WGS84), für räumliche Suche
);


-- =============================================================================
-- TABELLE 4: publishers
-- Verlage der Bücher.
-- =============================================================================
CREATE TABLE publishers (
    publisher_id SERIAL       PRIMARY KEY,
    name         VARCHAR(200) NOT NULL UNIQUE,
    country      VARCHAR(100)
);


-- =============================================================================
-- TABELLE 5: authors
-- Autoren der Bücher.
-- =============================================================================
CREATE TABLE authors (
    author_id  SERIAL       PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL
);


-- =============================================================================
-- TABELLE 6: genres
-- Buchgenres (z.B. 'Roman', 'Fantasy' etc.).
-- =============================================================================
CREATE TABLE genres (
    genre_id SERIAL       PRIMARY KEY,
    name     VARCHAR(100) NOT NULL UNIQUE
);


-- =============================================================================
-- TABELLE 7: books
-- Tabelle mit allen Büchern. 
-- Repräsentiert die Ausgabe eines Buches, also kein eigenes Exemplar.
-- =============================================================================
CREATE TABLE books (
    book_id          SERIAL       PRIMARY KEY,
    publisher_id     INT          REFERENCES publishers(publisher_id) ON DELETE SET NULL,
    isbn             VARCHAR(20)  UNIQUE,
    title            VARCHAR(300) NOT NULL,
    publication_year INT,
    language         VARCHAR(50)  NOT NULL DEFAULT 'Deutsch'
);

CREATE INDEX idx_books_title ON books(title); -- Sinnvoll für schnellere Suche nach Buchtiteln


-- =============================================================================
-- TABELLE 8: book_authors (Verbindungstabelle M:N)
-- Verbindet Bücher mit ihren Autoren (Mehrfachautoren möglich).
-- =============================================================================
CREATE TABLE book_authors (
    book_id   INT NOT NULL REFERENCES books(book_id)     ON DELETE CASCADE,
    author_id INT NOT NULL REFERENCES authors(author_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id) -- Zusammen glegter Primärschlüssel verhindert doppelte Einträge für dasselbe Buch + denselben Autor
);


-- =============================================================================
-- TABELLE 9: book_genres (Verbindungstabelle M:N)
-- Verbindet Bücher mit Genres (ein Buch kann mehrere Genres haben).
-- =============================================================================
CREATE TABLE book_genres (
    book_id  INT NOT NULL REFERENCES books(book_id)  ON DELETE CASCADE,
    genre_id INT NOT NULL REFERENCES genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, genre_id) -- Zusammen glegter Primärschlüssel verhindert doppelte Einträge für dasselbe Buch + dasselbe Genre
);


-- =============================================================================
-- TABELLE 10: book_listings
-- Ein konkretes Buchexemplar, das ein User zum Ausleihen anbietet.
-- condition zum einordnen vom Zustand des Buches: 'Neu', 'Sehr gut', 'Gut', 'Akzeptabel', 'Schlecht'
-- is_available: False sobald das Buch verliehen werden soll. True nach Rückgabe.
-- =============================================================================
CREATE TABLE book_listings (
    listing_id        SERIAL       PRIMARY KEY,
    book_id           INT          NOT NULL REFERENCES books(book_id)          ON DELETE RESTRICT,
    owner_id          INT          NOT NULL REFERENCES users(user_id)          ON DELETE CASCADE,
    condition         VARCHAR(50)  NOT NULL CHECK (condition IN ('Neu','Sehr gut','Gut','Akzeptabel','Schlecht')),
    max_loan_days     INT          NOT NULL DEFAULT 14 CHECK (max_loan_days > 0),
    is_available      BOOLEAN      NOT NULL DEFAULT TRUE,
    notes             TEXT
);


-- =============================================================================
-- TABELLE 11: meeting_slots
-- Zeitfenster, die ein User für Buch-Übergaben anbietet.
-- Verbunden mit users, damit derselbe Slot für Abholung und Rückgabe
-- verschiedener Bücher genutzt werden kann.
-- max_attendees: wie viele Personen sich pro Slot anmelden dürfen.
-- =============================================================================
CREATE TABLE meeting_slots (
    slot_id        SERIAL  PRIMARY KEY,
    user_id        INT     NOT NULL REFERENCES users(user_id)     ON DELETE CASCADE,
    address_id     INT     NOT NULL REFERENCES addresses(address_id) ON DELETE RESTRICT,
    available_date DATE    NOT NULL,
    slot_start     TIME    NOT NULL,
    slot_end       TIME    NOT NULL,
    max_attendees  INT     NOT NULL DEFAULT 1 CHECK (max_attendees > 0),
    CONSTRAINT chk_slot_times CHECK (slot_end > slot_start) -- Sicherstellen, dass Endzeit nach Startzeit liegt
);


-- =============================================================================
-- TABELLE 12: slot_signups (Verbindungstabelle M:N)
-- Anmeldungen von Usern zu Meeting-Slots.
-- listing_id (nullable): bei Abholungen das reservierte Buch, bei Rückgabe-Anmeldungen NULL.
-- UNIQUE(listing_id) verhindert Doppel-Reservierungen desselben Buches.
-- Bei Rückgabe eines Buches wird der Abholungs-Signup gelöscht,
-- damit das Listing erneut reserviert werden kann.
-- =============================================================================
CREATE TABLE slot_signups (
    signup_id    SERIAL     PRIMARY KEY,
    slot_id      INT        NOT NULL REFERENCES meeting_slots(slot_id)    ON DELETE CASCADE,
    user_id      INT        NOT NULL REFERENCES users(user_id)            ON DELETE CASCADE,
    listing_id   INT                 REFERENCES book_listings(listing_id) ON DELETE RESTRICT,
    signed_up_at TIMESTAMP  NOT NULL DEFAULT NOW(),
    UNIQUE (slot_id, user_id),
    UNIQUE (listing_id)
);


-- =============================================================================
-- TABELLE 13: loans
-- Ausleihtransaktionen.
-- Dreifachbeziehung: verbindet users (Ausleiher) + book_listings + meeting_slots.
-- slot_id: vereinbarter Abholtermin
-- return_slot_id: vereinbarter Rückgabetermin (nullable, da nicht sofort bei Ausleihe festgelegt werden muss)
-- return_date IS NULL -> Buch noch nicht zurückgegeben
-- return_date IS NOT NULL -> Buch zurückgegeben
-- due_date < CURRENT_DATE AND return_date IS NULL -> überfällig
-- =============================================================================
CREATE TABLE loans (
    loan_id        SERIAL  PRIMARY KEY,
    listing_id     INT     NOT NULL REFERENCES book_listings(listing_id)  ON DELETE RESTRICT,
    borrower_id    INT     NOT NULL REFERENCES users(user_id)             ON DELETE RESTRICT,
    slot_id        INT     NOT NULL REFERENCES meeting_slots(slot_id)     ON DELETE RESTRICT,
    return_slot_id INT              REFERENCES meeting_slots(slot_id)     ON DELETE RESTRICT,
    loan_date      DATE    NOT NULL DEFAULT CURRENT_DATE,
    due_date       DATE    NOT NULL,
    return_date    DATE,
    CONSTRAINT chk_due_date CHECK (due_date > loan_date)
);

CREATE INDEX idx_loans_borrower ON loans(borrower_id); -- Häufige Abfrage: alle Ausleihen eines bestimmten Users
CREATE INDEX idx_loans_active ON loans(return_date) WHERE return_date IS NULL; -- Häufige Abfrage: alle aktiven Ausleihen





-- =============================================================================
-- DUMMY-DATEN
-- Realistische Testdaten für alle Tabellen.
-- =============================================================================

-- -------------------------
-- Daten für: users (12)
-- -------------------------
INSERT INTO users (first_name, last_name, email, phone) VALUES
    ('Anna',    'Müller',   'anna.mueller@example.de',    '+49 30 12345678'),
    ('Jonas',   'Schmidt',   'jonas.schmidt@example.de',   '+49 89 23456789'),
    ('Laura',   'Weber',     'laura.weber@example.de',     '+49 40 34567890'),
    ('Lukas',   'Fischer',   'lukas.fischer@example.de',   '+49 211 45678901'),
    ('Sophie',  'Becker',    'sophie.becker@example.de',   '+49 69 56789012'),
    ('Max',     'Hoffmann',  'max.hoffmann@example.de',    '+49 711 67890123'),
    ('Lena',    'Schulz',    'lena.schulz@example.de',     '+49 30 78901234'),
    ('Felix',   'Koch',      'felix.koch@example.de',      '+49 351 89012345'),
    ('Marie',   'Bauer',     'marie.bauer@example.de',     '+49 511 90123456'),
    ('Tim',     'Richter',   'tim.richter@example.de',     '+49 221 01234567'),
    ('Julia',   'Klein',     'julia.klein@example.de',     '+49 30 11223344'),
    ('Stefan',  'Wolf',      'stefan.wolf@example.de',     '+49 89 22334455');


-- -------------------------
-- Daten für: postal_codes (10)
-- -------------------------
INSERT INTO postal_codes (postal_code, city) VALUES
    ('10117', 'Berlin'),
    ('80331', 'München'),
    ('20354', 'Hamburg'),
    ('40212', 'Düsseldorf'),
    ('60313', 'Frankfurt'),
    ('70173', 'Stuttgart'),
    ('10405', 'Berlin'),
    ('01069', 'Dresden'),
    ('30159', 'Hannover'),
    ('50667', 'Köln');


-- -------------------------
-- Daten für: addresses (12)
-- -------------------------
-- Latitude und Longitude stellen realistische Koordinaten für die Stadtmitte der jeweiligen Stadt dar
INSERT INTO addresses (user_id, postal_code_id, street, house_number, country, latitude, longitude) VALUES
    (1,   1, 'Unter den Linden',    '10',  'Deutschland',  52.5200,  13.4050),
    (2,   2, 'Marienplatz',         '1',   'Deutschland',  48.1370,  11.5750),
    (3,   3, 'Jungfernstieg',       '5',   'Deutschland',  53.5500,  10.0000),
    (4,   4, 'Königsallee',         '30',  'Deutschland',  51.2270,   6.7730),
    (5,   5, 'Zeil',                '12',  'Deutschland',  50.1100,   8.6820),
    (6,   6, 'Königstraße',         '8',   'Deutschland',  48.7760,   9.1830),
    (7,   7, 'Hauptstraße',          '45',  'Deutschland',  52.5200,  13.4050),
    (8,   8, 'Prager Straße',       '3',   'Deutschland',  51.0500,  13.7370),
    (9,   9, 'Marktplatz',           '2',   'Deutschland',  52.3760,   9.7320),
    (10, 10, 'Schildergasse',       '15',  'Deutschland',  50.9380,   6.9600),
    (11,  1, 'Friedrichstraße',     '22',  'Deutschland',  52.5200,  13.4050),
    (12,  2, 'Sendlinger Straße',   '7',   'Deutschland',  48.1370,  11.5750);


-- -------------------------
-- Daten für: publishers (10)
-- -------------------------
INSERT INTO publishers (name, country) VALUES
    ('Penguin Books',             'USA'),
    ('HarperCollins',             'USA'),
    ('Carlsen Verlag',            'Deutschland'),
    ('Shueisha',                  'Japan'),
    ('Hanser Verlag',             'Deutschland'),
    ('S. Fischer Verlag',         'Deutschland'),
    ('Tor Books',                 'USA'),
    ('Bloomsbury Publishing',     'UK'),
    ('Doubleday',                 'USA'),
    ('VIZ Media',                 'USA');


-- -------------------------
-- Daten für: authors (11)
-- -------------------------
INSERT INTO authors (first_name, last_name) VALUES
    ('R.F.',        'Kuang'),
    ('Gabrielle',   'Zevin'),
    ('Matt',        'Haig'),
    ('Bonnie',      'Garmus'),
    ('James',       'Clear'),
    ('Hanya',       'Yanagihara'),
    ('Travis',      'Baldree'),
    ('Gege',        'Akutami'),
    ('Tatsuki',     'Fujimoto'),
    ('Tatsuya',     'Endo'),
    ('Koyoharu',    'Gotouge');


-- -------------------------
-- Daten für: genres (10)
-- -------------------------
INSERT INTO genres (name) VALUES
    ('Roman'),
    ('Thriller'),
    ('Sachbuch'),
    ('Fantasy'),
    ('Science-Fiction'),
    ('Manga'),
    ('Cozy Fantasy'),
    ('Historischer Roman'),
    ('Philosophie'),
    ('Action');


-- -------------------------
-- Daten für: books (12)
-- -------------------------
INSERT INTO books (publisher_id, isbn, title, publication_year, language) VALUES
    (2,  '978-0-06-328198-4', 'Yellowface',                             2023, 'Englisch'),
    (1,  '978-0-59-332140-0', 'Tomorrow, and Tomorrow, and Tomorrow',   2022, 'Englisch'),
    (8,  '978-1-78-670627-4', 'The Midnight Library',                   2020, 'Englisch'),
    (9,  '978-0-38-554734-7', 'Lessons in Chemistry',                   2022, 'Englisch'),
    (1,  '978-0-73-522048-5', 'Atomic Habits',                          2018, 'Englisch'),
    (9,  '978-0-38-553369-4', 'A Little Life',                          2015, 'Englisch'),
    (7,  '978-1-25-032220-0', 'Legends & Lattes',                       2022, 'Englisch'),
    (2,  '978-0-06-313301-5', 'Babel',                                  2022, 'Englisch'),
    (3,  '978-3-55-179371-3', 'Jujutsu Kaisen',                  2020, 'Deutsch'),
    (3,  '978-3-55-179670-7', 'Chainsaw Man',                    2021, 'Deutsch'),
    (10, '978-1-97-472681-3', 'Spy x Family',                    2020, 'Englisch'),
    (4,  '978-4-08-880723-3', 'Kimetsu no Yaiba',                2020, 'Japanisch');

-- ------------------------
-- book_authors (M:N)
-- Verbindet Bücher mit ihren Autoren
-- ------------------------
INSERT INTO book_authors (book_id, author_id) VALUES
    (1,  1),
    (2,  2),
    (3,  3),
    (4,  4),
    (5,  5),
    (6,  6),
    (7,  7),
    (8,  1),
    (9,  8),
    (10, 9),
    (11, 10),
    (12, 11);

-- ------------------------
-- book_genres (M:N)
-- Verbindet Bücher mit Genres
-- ------------------------
INSERT INTO book_genres (book_id, genre_id) VALUES
    (1, 1),
    (1, 2),
    (2, 1),
    (3, 1),
    (3, 4),
    (4, 1),
    (5, 3),
    (6, 1),
    (7, 7),
    (7, 4),
    (8, 4),
    (8, 8),
    (9, 6),
    (9, 10),
    (10, 6),
    (10, 10),
    (11, 6),
    (12, 6),
    (12, 10);


-- -------------------------
-- Daten für: book_listings (12)
-- -------------------------
INSERT INTO book_listings (book_id, owner_id, condition, max_loan_days, is_available, notes) VALUES
    (1,  1,  'Sehr gut',   14, TRUE,  'Frisch gelesen, minimale Abnutzung'),
    (2,  2,  'Gut',        21, TRUE,  'Taschenbuch, sehr guter Zustand'),
    (3,  3,  'Sehr gut',   14, TRUE,  NULL),
    (4,  4,  'Gut',        14, TRUE,  'Klebezettel innen - lassen sich lösen'),
    (5,  5,  'Neu',        30, TRUE,  'Ungelesen, Geschenk erhalten'),
    (6,  6,  'Gut',        21, TRUE,  'Emotional, aber makellos'),
    (7,  7,  'Sehr gut',   14, TRUE,  NULL),
    (8,  8,  'Neu',        14, TRUE,  'Hardcover, wie neu'),
    (9,  9,  'Sehr gut',   10, TRUE,  'Erstausgabe, Folie noch drauf'),
    (10, 10, 'Gut',        10, TRUE,  NULL),
    (11, 11, 'Neu',        14, TRUE,  'Wie neu, kaum geöffnet'),
    (12, 12, 'Akzeptabel', 14, TRUE,  'Etwas vergilbt, inhaltlich vollständig');


-- -------------------------
-- Daten für: meeting_slots (16)
-- user_id ist der User,
-- der den Slot anbietet.
-- -------------------------
INSERT INTO meeting_slots (user_id, address_id, available_date, slot_start, slot_end, max_attendees) VALUES
    (1,  1,  '2026-03-15', '10:00', '11:00', 2),
    (1,  1,  '2026-03-16', '14:00', '15:00', 1),
    (2,  2,  '2026-03-14', '09:00', '10:00', 1),
    (3,  3,  '2026-03-17', '11:00', '12:00', 2),
    (4,  4,  '2026-03-18', '15:00', '16:00', 1),
    (5,  5,  '2026-03-13', '10:00', '11:30', 1),
    (6,  6,  '2026-03-19', '13:00', '14:00', 1),
    (7,  7,  '2026-03-20', '17:00', '18:00', 1),
    (8,  8,  '2026-03-14', '08:00', '09:00', 1),
    (9,  9,  '2026-03-21', '10:00', '11:00', 1),
    (10, 10, '2026-03-15', '16:00', '17:00', 3),
    (11, 11, '2026-03-22', '12:00', '13:00', 1),
    (5,  5,  '2026-03-20', '10:00', '11:00', 1),
    (2,  2,  '2026-02-20', '14:00', '15:00', 1),
    (6,  6,  '2026-03-14', '11:00', '12:00', 2),
    (7,  7,  '2026-03-07', '09:00', '10:00', 1);


-- -------------------------
-- Daten für: slot_signups (14)
-- listing_id = reserviertes Buch (NULL bei Rückgabe-Anmeldungen)
-- Jeder Borrower meldet sich beim Slot des Buch-Owners an
-- -------------------------
INSERT INTO slot_signups (slot_id, user_id, listing_id) VALUES
    (3,  4,  2),
    (4,  4,  3),
    (5,  5,  4),
    (6,  7,  5),
    (7,  8,  6),
    (8,  12, 7),
    (9,  1,  8),
    (10, 10, 9),
    (11, 11, 10),
    (12, 12, 11),
    (13, 7,  NULL),
    (14, 3,  NULL),
    (15, 8,  NULL),
    (16, 12, NULL);

-- Reservierte Bücher direkt bei Anmeldung sperren
UPDATE book_listings
SET is_available = FALSE
WHERE listing_id IN (2, 3, 4, 5, 6, 7, 8, 9, 10, 11); -- Alle Listings mit einer Reservierung in slot_signups auf nicht verfügbar setzen


-- -------------------------
-- Daten für: loans (10)
-- -------------------------
INSERT INTO loans (listing_id, borrower_id, slot_id, return_slot_id, loan_date, due_date, return_date) VALUES
    -- Aktive Ausleihen (return_date = NULL)
    (10,  2,  10,  NULL, '2026-03-15', '2026-03-29', NULL),
    (3,  4,  4,  NULL, '2026-03-18', '2026-04-01', NULL),
    (8,  1,  9,  NULL, '2026-03-14', '2026-03-28', NULL),
    (9,  10, 10, NULL, '2026-03-21', '2026-04-04', NULL),
    (10, 11, 11, NULL, '2026-03-22', '2026-04-01', NULL),
    -- Überfällig (return_date = NULL, due_date in der Vergangenheit)
    (4,  5,  5,  NULL, '2026-02-10', '2026-02-20', NULL),
    -- Zurückgegeben (return_date gesetzt, return_slot_id gesetzt)
    (5,  7,  6,  13,   '2026-03-13', '2026-04-12', '2026-03-20'),
    (2,  3,  3,  14,   '2026-02-01', '2026-02-22', '2026-02-20'),
    (6,  8,  7,  15,   '2026-03-01', '2026-03-15', '2026-03-14'),
    (7,  12, 8,  16,   '2026-02-15', '2026-03-08', '2026-03-07');

-- Abholungs Signups zurückgegebener Bücher entfernen, damit die Listings wieder verfügbar werden
DELETE FROM slot_signups WHERE listing_id IN (2, 5, 6, 7);
UPDATE book_listings SET is_available = TRUE WHERE listing_id IN (2, 5, 6, 7);