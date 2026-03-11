-- =============================================================================
-- Buchtausch App: Abfrage-Vorlagen
--
-- Vorlagen für häufige SQL-Abfragen im normalen Betrieb der App.
-- Platzhalter sind mit <  > gekennzeichnet und müssen ersetzt werden.
--
-- INHALT:
--   1.  Bücher nach Stadt suchen
--   2.  Bücher in der Nähe suchen
--   3.  Bücher nach Titel suchen
--   4.  Bücher nach Autor suchen
--   5.  Bücher nach Genre suchen
--   6.  Bücher nach Sprache suchen
--   7.  Kombinierte Buchsuche
--   8.  Meeting-Slots einer Person bis zu einem Datum
--   9.  Alle Listings eines Users
--   10. Listing-Details mit verfügbaren Slots
--   11. Aktive Ausleihen eines Users
--   12. Ausleihhistorie eines Users
--   13. Alle überfälligen Ausleihen
--   14. Alle aktiven Ausleihen
--   15. User nach Name oder E-Mail suchen
--   16. Alle Anmeldungen auf einem Slot anzeigen
--   17. Auf einen Slot anmelden
--   18. Neues Buch (Metadaten) anlegen
--   19. Neues Listing anlegen
--   20. Neuen Meeting-Slot anlegen
--   21. Neue Adresse anlegen
-- =============================================================================


-- =============================================================================
-- 1. Listings nach Stadt suchen
--    Zeigt alle verfügbaren Listings, deren Besitzer in einer bestimmten Stadt eine Adresse haben.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    u.first_name || ' ' || u.last_name AS verleiher,
    u.phone AS telefon,
    bl.condition AS zustand,
    bl.max_loan_days AS max_tage,
    bl.is_available,
    pc.city
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
JOIN addresses ad ON ad.user_id = bl.owner_id
JOIN postal_codes pc ON ad.postal_code_id = pc.postal_code_id
WHERE bl.is_available = TRUE
  AND pc.city = '<stadt>' -- Hier Stadt eingeben
ORDER BY b.title;


-- =============================================================================
-- 2. Listings in der Nähe suchen (GPS Bounding-Box)
--    Zeigt alle verfügbaren Listings, deren Besitzer sich innerhalb eines
--    geografischen Rechtecks befinden (latitude/longitude in WGS84).
--    Die Koordinaten der Eckpunkte können z. B. aus einem Kartenausschnitt
--    der App berechnet werden.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    u.first_name || ' ' || u.last_name AS verleiher,
    u.phone AS telefon,
    bl.condition AS zustand,
    bl.max_loan_days AS max_tage,
    ad.latitude,
    ad.longitude,
    pc.city
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
JOIN addresses ad ON ad.user_id = bl.owner_id
JOIN postal_codes pc ON ad.postal_code_id = pc.postal_code_id
WHERE bl.is_available = TRUE
  AND ad.latitude  BETWEEN <lat_min> AND <lat_max>  -- z. B. 52.40 AND 52.65 für Berlin
  AND ad.longitude BETWEEN <lon_min> AND <lon_max>  -- z. B. 13.20 AND 13.60 für Berlin
ORDER BY b.title;


-- =============================================================================
-- 3. Bücher nach Titel suchen
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    u.first_name || ' ' || u.last_name AS verleiher,
    bl.condition AS zustand,
    bl.is_available
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
WHERE b.title ILIKE '<suchwort>' -- Hier Suchwort eingeben
  AND bl.is_available = TRUE
ORDER BY b.title;


-- =============================================================================
-- 4. Bücher nach Autor suchen
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    u.first_name || ' ' || u.last_name AS verleiher,
    bl.condition AS zustand,
    bl.is_available
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
WHERE (a.first_name ILIKE '<autor>' OR a.last_name ILIKE '<autor>') -- Hier Autor eingeben
  AND bl.is_available = TRUE
ORDER BY a.last_name, b.title;


-- =============================================================================
-- 5. Bücher nach Genre suchen
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    g.name AS genre,
    u.first_name || ' ' || u.last_name AS verleiher,
    bl.condition AS zustand,
    bl.is_available
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
JOIN book_genres bg ON b.book_id = bg.book_id
JOIN genres g ON bg.genre_id = g.genre_id
WHERE g.name = '<genre>' -- Hier Genre eingeben
  AND bl.is_available = TRUE
ORDER BY b.title;


-- =============================================================================
-- 6. Bücher nach Sprache suchen
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    b.language AS sprache,
    u.first_name || ' ' || u.last_name AS verleiher,
    bl.condition AS zustand
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
WHERE b.language = '<sprache>' -- Hier Sprache eingeben, z.B. 'Deutsch'
  AND bl.is_available = TRUE
ORDER BY b.title;


-- =============================================================================
-- 7. Kombinierte Buchsuche
--    Nicht benötigte Filter auskommentieren.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    g.name AS genre,
    b.language AS sprache,
    u.first_name || ' ' || u.last_name AS verleiher,
    pc.city,
    bl.condition AS zustand,
    bl.max_loan_days AS max_tage
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
JOIN addresses ad ON ad.user_id = bl.owner_id
JOIN postal_codes pc ON ad.postal_code_id = pc.postal_code_id
JOIN book_genres bg ON b.book_id = bg.book_id
JOIN genres g ON bg.genre_id = g.genre_id
WHERE bl.is_available = TRUE
  AND pc.city = '<stadt>' -- Hier Stadt eingeben
  AND g.name = '<genre>' -- Hier Genre eingeben
  AND b.language = '<sprache>' -- Hier Sprache eingeben
ORDER BY b.title;


-- =============================================================================
-- 8. Verfügbare Meeting Slots einer Person bis zu einem bestimmten Datum
--    Zeigt nur Slots mit noch freien Plätzen.
-- =============================================================================
SELECT
    ms.slot_id,
    ms.available_date,
    ms.slot_start || ' - ' || ms.slot_end AS zeitfenster,
    ad.street || ' ' || ad.house_number || ', ' || pc.postal_code || ' ' || pc.city AS treffpunkt,
    ms.max_attendees - COUNT(ss.signup_id) AS plätze_frei
FROM meeting_slots ms
JOIN addresses ad ON ms.address_id = ad.address_id
JOIN postal_codes pc ON ad.postal_code_id = pc.postal_code_id
LEFT JOIN slot_signups ss ON ms.slot_id = ss.slot_id
WHERE ms.user_id = <user_id> -- Hier user_id eingeben
  AND ms.available_date BETWEEN CURRENT_DATE AND '<bis_datum>' -- Hier Enddatum eingeben
GROUP BY ms.slot_id, ms.available_date, ms.slot_start, ms.slot_end,
         ms.max_attendees, ad.street, ad.house_number, pc.postal_code, pc.city
HAVING ms.max_attendees - COUNT(ss.signup_id) > 0
ORDER BY ms.available_date, ms.slot_start;


-- =============================================================================
-- 9. Alle Listings eines Users
--    Zeigt alle Bücher die ein User anbietet mit aktuellem Verfügbarkeitsstatus.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name AS autor,
    bl.condition AS zustand,
    bl.max_loan_days AS max_tage,
    bl.is_available AS verfügbar,
    bl.notes
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE bl.owner_id = <user_id> -- Hier user_id eingeben
ORDER BY bl.is_available DESC, b.title;


-- =============================================================================
-- 10. Listing-Details mit allen verfügbaren Meeting Slots zum Abholen
--    Zeigt alle Details zu einem Listing inklusive aller zukünftigen Slots mit freien Plätzen.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title AS buchtitel,
    a.first_name || ' ' || a.last_name AS autor,
    u.first_name || ' ' || u.last_name AS besitzer,
    u.phone AS telefon,
    bl.condition AS zustand,
    bl.max_loan_days AS max_tage,
    ms.slot_id,
    ms.available_date,
    ms.slot_start || ' - ' || ms.slot_end AS zeitfenster,
    ad.street || ' ' || ad.house_number || ', ' || pc.postal_code || ' ' || pc.city AS treffpunkt,
    ms.max_attendees - COUNT(ss.signup_id) AS plätze_frei
FROM book_listings bl
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u ON bl.owner_id = u.user_id
JOIN meeting_slots ms ON ms.user_id = bl.owner_id
JOIN addresses ad ON ms.address_id = ad.address_id
JOIN postal_codes pc ON ad.postal_code_id = pc.postal_code_id
LEFT JOIN slot_signups ss ON ms.slot_id = ss.slot_id
WHERE bl.listing_id = <listing_id> -- Hier die listing_id eingeben
  AND ms.available_date >= CURRENT_DATE
GROUP BY bl.listing_id, b.title, a.first_name, a.last_name, u.first_name, u.last_name,
         u.phone, bl.condition, bl.max_loan_days, bl.notes,
         ms.slot_id, ms.available_date, ms.slot_start, ms.slot_end, ms.max_attendees,
         ad.street, ad.house_number, pc.postal_code, pc.city
HAVING ms.max_attendees - COUNT(ss.signup_id) > 0
ORDER BY ms.available_date, ms.slot_start;


-- =============================================================================
-- 11. Aktive Ausleihen eines Users
--     Zeigt alle Bücher die ein User gerade ausgeliehen hat, mit Fälligkeitsdatum.
-- =============================================================================
SELECT
    lo.loan_id,
    b.title AS buchtitel,
    a.first_name || ' ' || a.last_name AS autor,
    u_owner.first_name || ' ' || u_owner.last_name AS verleiher,
    u_owner.phone AS verleiher_telefon,
    lo.loan_date AS ausgeliehen_am,
    lo.due_date AS fällig_bis,
    lo.due_date - CURRENT_DATE AS tage_verbleibend,
    CASE
        WHEN lo.due_date < CURRENT_DATE THEN 'überfällig'
        WHEN lo.due_date - CURRENT_DATE <= 3 THEN 'bald fällig'
        ELSE 'aktiv'
    END AS status
FROM loans lo
JOIN book_listings bl ON lo.listing_id = bl.listing_id
JOIN books b ON bl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN users u_owner ON bl.owner_id = u_owner.user_id
WHERE lo.borrower_id = <user_id> -- Hier user_id eingeben
  AND lo.return_date IS NULL
ORDER BY lo.due_date;


-- =============================================================================
-- 12. Ausleihhistorie eines Users
--     Alle abgeschlossenen Ausleihen eines Users.
-- =============================================================================
SELECT
    lo.loan_id,
    b.title AS buchtitel,
    u_owner.first_name || ' ' || u_owner.last_name AS verleiher,
    lo.loan_date AS ausgeliehen_am,
    lo.due_date AS fällig_war,
    lo.return_date AS zurückgegeben_am,
    lo.return_date - lo.loan_date AS ausleih_dauer_tage
FROM loans lo
JOIN book_listings bl ON lo.listing_id = bl.listing_id
JOIN books b ON bl.book_id = b.book_id
JOIN users u_owner ON bl.owner_id = u_owner.user_id
WHERE lo.borrower_id = <user_id> -- Hier user_id eingeben
  AND lo.return_date IS NOT NULL
ORDER BY lo.return_date DESC;


-- =============================================================================
-- 13. Alle überfälligen Ausleihen
-- =============================================================================
SELECT
    lo.loan_id,
    b.title AS buchtitel,
    u_borrow.first_name || ' ' || u_borrow.last_name AS ausleiher,
    u_borrow.email,
    u_borrow.phone,
    u_owner.first_name || ' ' || u_owner.last_name AS verleiher,
    lo.due_date AS fällig_seit,
    CURRENT_DATE - lo.due_date AS tage_überfällig
FROM loans lo
JOIN book_listings bl ON lo.listing_id = bl.listing_id
JOIN books b ON bl.book_id = b.book_id
JOIN users u_borrow ON lo.borrower_id = u_borrow.user_id
JOIN users u_owner ON bl.owner_id = u_owner.user_id
WHERE lo.return_date IS NULL
  AND lo.due_date < CURRENT_DATE
ORDER BY tage_überfällig DESC;


-- =============================================================================
-- 14. Alle Ausleihen mit Status
-- =============================================================================
SELECT
    lo.loan_id,
    b.title AS buchtitel,
    u_owner.first_name || ' ' || u_owner.last_name AS verleiher,
    u_borrow.first_name || ' ' || u_borrow.last_name AS ausleiher,
    ms.available_date AS abholtermin,
    lo.loan_date,
    lo.due_date AS fällig_bis,
    lo.return_date,
    CASE
        WHEN lo.return_date IS NOT NULL THEN 'zurückgegeben'
        WHEN lo.due_date < CURRENT_DATE THEN 'überfällig'
        ELSE 'aktiv'
    END AS status
FROM loans lo
JOIN book_listings bl ON lo.listing_id = bl.listing_id
JOIN books b ON bl.book_id = b.book_id
JOIN users u_owner ON bl.owner_id = u_owner.user_id
JOIN users u_borrow ON lo.borrower_id = u_borrow.user_id
JOIN meeting_slots ms ON lo.slot_id = ms.slot_id
ORDER BY lo.loan_date DESC;


-- =============================================================================
-- 15. User nach Name oder E-Mail suchen
-- =============================================================================
SELECT
    u.user_id,
    u.first_name || ' ' || u.last_name AS name,
    u.email,
    u.phone,
    u.created_at
FROM users u
WHERE u.first_name ILIKE '<suchwort>' -- Optional Suchwerte hier, ansonsten
   OR u.last_name  ILIKE '<suchwort>' -- auskommentieren für keine Filter
   OR u.email      ILIKE '<suchwort>' -- (Wenn kein Filter verwendet wird, werden alle User angezeigt)
ORDER BY u.last_name, u.first_name;


-- =============================================================================
-- 16. Alle Anmeldungen auf einem Slot anzeigen
--     Zeigt wer sich auf einen bestimmten Slot angemeldet hat und
--     wie viele Plätze noch frei sind.
-- =============================================================================
SELECT
    ms.slot_id,
    ms.available_date,
    ms.slot_start || ' - ' || ms.slot_end AS zeitfenster,
    ms.max_attendees AS max_plaetze,
    u.first_name || ' ' || u.last_name AS angemeldet_user,
    bl.listing_id,
    b.title AS reserviertes_buch
FROM meeting_slots ms
LEFT JOIN slot_signups ss ON ms.slot_id = ss.slot_id
LEFT JOIN users u ON ss.user_id = u.user_id
LEFT JOIN book_listings bl ON ss.listing_id = bl.listing_id
LEFT JOIN books b ON bl.book_id = b.book_id
WHERE ms.slot_id = <slot_id> -- Hier slot_id eingeben
ORDER BY u.last_name;


-- =============================================================================
-- 17. Auf einen Slot anmelden
-- =============================================================================
INSERT INTO slot_signups (slot_id, user_id, listing_id) VALUES
    (<slot_id>, <user_id>, <listing_id>); -- slot_id und user_id eintrage. listing_id optional (wenn nicht dann NULL eintragen)


-- =============================================================================
-- 18. Neues Buch anlegen
--     Autor und Genre nach dem INSERT separat verknüpfen mit der neu generierten book_id.
-- =============================================================================
INSERT INTO books (publisher_id, isbn, title, publication_year, language) VALUES
    (<publisher_id>, '<isbn>', '<titel>', <erscheinungsjahr>, '<sprache>'); -- z. B. 'Deutsch', 'Englisch'

-- Autor verknüpfen (book_id der eben eingefügten Zeile abfragen: SELECT MAX(book_id) FROM books;)
INSERT INTO book_authors (book_id, author_id) VALUES
    (<book_id>, <author_id>);

-- Genre verknüpfen
INSERT INTO book_genres (book_id, genre_id) VALUES
    (<book_id>, <genre_id>);


-- =============================================================================
-- 19. Neues Listing anlegen
-- =============================================================================
INSERT INTO book_listings (book_id, owner_id, condition, max_loan_days, notes) VALUES
    (<book_id>, <owner_id>, '<condition>', <max_loan_days>, '<notizen>'); -- notizen optional, stattdessen NULL möglich


-- =============================================================================
-- 20. Neuen Meeting-Slot anlegen
-- =============================================================================
INSERT INTO meeting_slots (user_id, address_id, available_date, slot_start, slot_end, max_attendees) VALUES
    (<user_id>, <address_id>, '<datum>', '<uhrzeit_von>', '<uhrzeit_bis>', <max_teilnehmer>);


-- =============================================================================
-- 21. Neue Adresse anlegen
--     postal_code_id prüfen: SELECT postal_code_id, postal_code, city FROM postal_codes;
--     Falls die PLZ noch nicht existiert, zuerst in postal_codes einfügen:
--     INSERT INTO postal_codes (postal_code, city) VALUES ('<plz>', '<stadt>');
--     latitude und longitude sind optional (Stadtmitte-Koordinaten empfohlen).
-- =============================================================================
INSERT INTO addresses (user_id, postal_code_id, street, house_number, country, latitude, longitude) VALUES
    (<user_id>, <postal_code_id>, '<strasse>', '<hausnummer>', 'Deutschland', <latitude>, <longitude>);
    -- latitude/longitude optional, stattdessen NULL eintragen