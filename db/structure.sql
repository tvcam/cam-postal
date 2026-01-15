CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "postal_codes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "code" varchar, "postal_code" varchar, "name_km" varchar, "name_en" varchar, "location_type" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_postal_codes_on_postal_code" ON "postal_codes" ("postal_code") /*application='CamPostal'*/;
CREATE INDEX "index_postal_codes_on_location_type" ON "postal_codes" ("location_type") /*application='CamPostal'*/;
CREATE INDEX "index_postal_codes_on_name_en" ON "postal_codes" ("name_en") /*application='CamPostal'*/;
CREATE VIRTUAL TABLE postal_codes_fts USING fts5(
        postal_code,
        name_km,
        name_en,
        content='postal_codes',
        content_rowid='id'
      )
/* postal_codes_fts(postal_code,name_km,name_en) */;
CREATE TABLE IF NOT EXISTS 'postal_codes_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'postal_codes_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'postal_codes_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'postal_codes_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TRIGGER postal_codes_ai AFTER INSERT ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(rowid, postal_code, name_km, name_en)
        VALUES (new.id, new.postal_code, new.name_km, new.name_en);
      END;
CREATE TRIGGER postal_codes_ad AFTER DELETE ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(postal_codes_fts, rowid, postal_code, name_km, name_en)
        VALUES ('delete', old.id, old.postal_code, old.name_km, old.name_en);
      END;
CREATE TRIGGER postal_codes_au AFTER UPDATE ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(postal_codes_fts, rowid, postal_code, name_km, name_en)
        VALUES ('delete', old.id, old.postal_code, old.name_km, old.name_en);
        INSERT INTO postal_codes_fts(rowid, postal_code, name_km, name_en)
        VALUES (new.id, new.postal_code, new.name_km, new.name_en);
      END;
INSERT INTO "schema_migrations" (version) VALUES
('20260114181406');

