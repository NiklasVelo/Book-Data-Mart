-- =============================================================================
-- Buchtausch App: Interaktions Beispiel
--
-- Nachdem die Datenbank mit buchtausch_app.sql befüllt wurde, können die folgenden
-- SQL Abfragen eine Interaktion zwischen zwei Nutzern simulieren
--
-- Szenario: Jonas (user_id= 2) möchte "Yellowface" von R.F. Kuang
-- von Anna (user_id= 1) ausleihen und zurückgeben.
-- =============================================================================


-- =============================================================================
-- SCHRITT 1: Jonas sucht verfügbare Bücher in seiner Nähe
-- =============================================================================
SELECT
    bl.listing_id,
    b.title,
    a.first_name || ' ' || a.last_name  AS autor,
    u.first_name || ' ' || u.last_name  AS verleiher,
    bl.condition                         AS zustand,
    bl.max_loan_days                     AS max_tage,
    ad.latitude,
    ad.longitude,
    pc.city
FROM book_listings bl
JOIN books         b   ON bl.book_id            = b.book_id
JOIN book_authors  ba  ON b.book_id             = ba.book_id
JOIN authors       a   ON ba.author_id          = a.author_id
JOIN users         u   ON bl.owner_id           = u.user_id
JOIN addresses     ad  ON ad.user_id            = bl.owner_id
JOIN postal_codes  pc  ON ad.postal_code_id     = pc.postal_code_id
WHERE bl.is_available = TRUE
  AND ad.latitude  BETWEEN 52.40 AND 52.65  -- Bounding-Box Berlin (Nord-Süd)
  AND ad.longitude BETWEEN 13.20 AND 13.60  -- Bounding-Box Berlin (West-Ost)
ORDER BY b.title;


-- =============================================================================
-- SCHRITT 2: Jonas filtert nach Genre "Roman"
-- =============================================================================
SELECT
    g.name                              AS genre,
    b.title,
    a.first_name || ' ' || a.last_name  AS autor,
    bl.listing_id,
    bl.condition,
    bl.is_available
FROM genres        g
JOIN book_genres   bg ON g.genre_id   = bg.genre_id
JOIN books         b  ON bg.book_id   = b.book_id
JOIN book_authors  ba ON b.book_id    = ba.book_id
JOIN authors       a  ON ba.author_id = a.author_id
JOIN book_listings bl ON b.book_id    = bl.book_id
WHERE g.name = 'Roman'
  AND bl.is_available = TRUE
ORDER BY b.title;


-- =============================================================================
-- SCHRITT 3: Jonas schaut sich Listing 1 im Detail an.
-- =============================================================================
SELECT
    bl.listing_id,
    b.title                                                         AS buchtitel,
    u.first_name || ' ' || u.last_name                             AS besitzer,
    u.phone                                                         AS telefon,
    bl.condition,
    bl.max_loan_days,
    bl.notes,
    ms.slot_id,
    ms.available_date,
    ms.slot_start || ' - ' || ms.slot_end                          AS zeitfenster,
    ad.street || ' ' || ad.house_number || ', '
        || pc.postal_code || ' ' || pc.city                        AS treffpunkt,
    ms.max_attendees - COUNT(ss.signup_id)                         AS plätze_frei
FROM book_listings   bl
JOIN books           b  ON bl.book_id          = b.book_id
JOIN users           u  ON bl.owner_id         = u.user_id
JOIN meeting_slots   ms ON ms.user_id          = bl.owner_id
JOIN addresses       ad ON ms.address_id       = ad.address_id
JOIN postal_codes    pc ON ad.postal_code_id   = pc.postal_code_id
LEFT JOIN slot_signups ss ON ms.slot_id        = ss.slot_id
WHERE bl.listing_id = 1 -- Jonas interessiert sich für listing 1 ("Yellowface" von Anna)
  AND ms.available_date >= CURRENT_DATE -- nur zukünftige Slots anzeigen
GROUP BY bl.listing_id, b.title, u.first_name, u.last_name, u.phone,
         bl.condition, bl.max_loan_days, bl.notes,
         ms.slot_id, ms.available_date, ms.slot_start, ms.slot_end, ms.max_attendees,
         ad.street, ad.house_number, pc.postal_code, pc.city
HAVING ms.max_attendees - COUNT(ss.signup_id) > 0 -- nur Slots mit freien Plätzen anzeigen
ORDER BY ms.available_date, ms.slot_start;


-- =============================================================================
-- SCHRITT 4: Jonas meldet sich für Slot 2 bei Anna an und reserviert das Buch
-- =============================================================================
INSERT INTO slot_signups (slot_id, user_id, listing_id)
VALUES (2, 2, 1);   -- slot_id = 2 ist ein freier Slot von Anna.

-- Buch bei Anmeldung direkt sperren (verhindert Doppel-Reservierung)
UPDATE book_listings
SET    is_available = FALSE
WHERE  listing_id = 1;


-- =============================================================================
-- SCHRITT 5: Ausleihe wird angelegt
-- =============================================================================
INSERT INTO loans (listing_id, borrower_id, slot_id, loan_date, due_date)
VALUES (
    1, -- listing_id: "Yellowface" von Anna
    2, -- borrower_id: Jonas
    2, -- slot_id: Annas Slot am 16.03.2026
    '2026-03-16', -- loan_date: Abholtag (= Slot-Datum)
    '2026-03-30' -- due_date: 14 Tage Leihfrist
);
-- return_slot bleibt zunächst NULL, da noch keine genaue Rückgabeplanung stattgefunden hat.
-- return_date bleibt ebenfalls NULL, da das Buch noch nicht zurückgegeben wurde.


-- =============================================================================
-- SCHRITT 6: Anna legt drei Rückgabe-Slots an, damit Jonas mehrere Optionen fürs Zurückgeben hat
-- =============================================================================
INSERT INTO meeting_slots (user_id, address_id, available_date, slot_start, slot_end, max_attendees)
VALUES
    (1, 1, '2026-03-26', '14:00', '15:00', 1),  -- -> slot_id = 17
    (1, 1, '2026-03-28', '09:00', '10:00', 1),  -- -> slot_id = 18
    (1, 1, '2026-03-30', '10:00', '11:00', 1);  -- -> slot_id = 19


-- =============================================================================
-- SCHRITT 7: Jonas schaut nach seinen aktiven Ausleihen, um zu sehen, wann er das Buch zurückgeben muss
-- =============================================================================
SELECT
    lo.loan_id,
    b.title                                           AS buchtitel,
    u_owner.first_name || ' ' || u_owner.last_name    AS verleiher,
    lo.loan_date                                      AS ausgeliehen_am,
    lo.due_date                                       AS fällig_bis,
    lo.due_date - CURRENT_DATE                        AS tage_verbleibend
FROM loans           lo
JOIN book_listings   bl      ON lo.listing_id  = bl.listing_id
JOIN books           b       ON bl.book_id     = b.book_id
JOIN users           u_owner ON bl.owner_id    = u_owner.user_id
WHERE lo.borrower_id  = 2 -- Jonas user_id
  AND lo.return_date IS NULL -- noch nicht zurückgegeben
ORDER BY lo.due_date;


-- =============================================================================
-- SCHRITT 8: Jonas sucht einen Rückgabe-Slot bei Anna.
-- Er weiß, dass er bis zum 30.03. zurückgeben muss und filtert Annas Slots auf diesen Zeitraum
-- =============================================================================
SELECT
    ms.slot_id,
    ms.available_date,
    ms.slot_start || ' - ' || ms.slot_end           AS zeitfenster,
    ad.street || ' ' || ad.house_number || ', '
        || pc.postal_code || ' ' || pc.city         AS treffpunkt,
    ms.max_attendees - COUNT(ss.signup_id)          AS plätze_frei                              
FROM meeting_slots   ms
JOIN addresses       ad ON ms.address_id       = ad.address_id
JOIN postal_codes    pc ON ad.postal_code_id   = pc.postal_code_id
LEFT JOIN slot_signups ss ON ms.slot_id = ss.slot_id
WHERE ms.user_id = 1
  AND ms.available_date BETWEEN CURRENT_DATE AND '2026-03-30'
GROUP BY ms.slot_id, ms.available_date, ms.slot_start, ms.slot_end,
         ms.max_attendees, ad.street, ad.house_number, pc.postal_code, pc.city
HAVING ms.max_attendees - COUNT(ss.signup_id) > 0
ORDER BY ms.available_date;


-- =============================================================================
-- SCHRITT 9: Jonas meldet sich für Slot 19 bei Anna an
-- und hinterlegt ihn in return_slot_id
-- =============================================================================
INSERT INTO slot_signups (slot_id, user_id, listing_id)
VALUES (19, 2, NULL);

-- Rückgabe-Slot in der Ausleihe hinterlegen:
UPDATE loans
SET    return_slot_id = 19
WHERE  loan_id = 11; -- loan_id = 11 ist die eben erstellte Ausleihe


-- =============================================================================
-- SCHRITT 10: Rückgabe abschließen
-- return_date setzen und Buch wieder verfügbar machen
-- =============================================================================
-- Rückgabe-Datum setzen
UPDATE loans
SET    return_date = '2026-03-30'
WHERE  loan_id = 11;

-- Buch wieder verfügbar machen
UPDATE book_listings
SET    is_available = TRUE
WHERE  listing_id = 1;

-- Abholungs-Signup/Reservierung löschen -> Listing kann wieder von anderen Nutzern reserviert werden
DELETE FROM slot_signups
WHERE  listing_id = 1;
