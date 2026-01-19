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
CREATE TABLE IF NOT EXISTS "site_stats" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "value" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_site_stats_on_name" ON "site_stats" ("name") /*application='CamPostal'*/;
CREATE TABLE IF NOT EXISTS "geocode_caches" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "lat" decimal(7,3) NOT NULL, "lng" decimal(7,3) NOT NULL, "postal_code" varchar, "area" varchar, "display_name" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_geocode_caches_on_lat_and_lng" ON "geocode_caches" ("lat", "lng") /*application='CamPostal'*/;
CREATE TABLE IF NOT EXISTS "search_logs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "query" varchar NOT NULL, "ip_address" varchar, "user_agent" varchar, "results_count" integer DEFAULT 0, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_search_logs_on_query" ON "search_logs" ("query") /*application='CamPostal'*/;
CREATE INDEX "index_search_logs_on_created_at" ON "search_logs" ("created_at") /*application='CamPostal'*/;
CREATE TABLE IF NOT EXISTS "api_access_logs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "ip_address" varchar, "user_agent" varchar, "endpoint" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_api_access_logs_on_created_at" ON "api_access_logs" ("created_at") /*application='CamPostal'*/;
CREATE INDEX "index_api_access_logs_on_ip_address" ON "api_access_logs" ("ip_address") /*application='CamPostal'*/;
CREATE TABLE IF NOT EXISTS "learned_aliases" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "search_term" varchar NOT NULL, "postal_code" varchar NOT NULL, "click_count" integer DEFAULT 0 NOT NULL, "search_count" integer DEFAULT 0 NOT NULL, "unique_ips" integer DEFAULT 0 NOT NULL, "promoted" boolean DEFAULT FALSE NOT NULL, "last_clicked_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_learned_aliases_on_search_term_and_postal_code" ON "learned_aliases" ("search_term", "postal_code") /*application='CamPostal'*/;
CREATE INDEX "index_learned_aliases_on_search_term" ON "learned_aliases" ("search_term") /*application='CamPostal'*/;
CREATE INDEX "index_learned_aliases_on_promoted" ON "learned_aliases" ("promoted") /*application='CamPostal'*/;
CREATE INDEX "index_learned_aliases_on_click_count" ON "learned_aliases" ("click_count") /*application='CamPostal'*/;
CREATE INDEX "index_learned_aliases_on_last_clicked_at" ON "learned_aliases" ("last_clicked_at") /*application='CamPostal'*/;
CREATE TABLE IF NOT EXISTS "feedbacks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "email" varchar, "message" text, "ip_address" varchar, "user_agent" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "read_at" datetime(6) /*application='CamPostal'*/);
INSERT INTO "schema_migrations" (version) VALUES
('20260119051311'),
('20260119051205'),
('20260119032117'),
('20260118085810'),
('20260118044035'),
('20260115055137'),
('20260115031238'),
('20260114181406');

