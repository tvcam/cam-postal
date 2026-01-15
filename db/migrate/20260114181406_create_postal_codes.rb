class CreatePostalCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :postal_codes do |t|
      t.string :code
      t.string :postal_code
      t.string :name_km
      t.string :name_en
      t.string :location_type

      t.timestamps
    end
    add_index :postal_codes, :postal_code
    add_index :postal_codes, :location_type
    add_index :postal_codes, :name_en

    # Create FTS5 virtual table for full-text search
    execute <<-SQL
      CREATE VIRTUAL TABLE postal_codes_fts USING fts5(
        postal_code,
        name_km,
        name_en,
        content='postal_codes',
        content_rowid='id'
      );
    SQL

    # Triggers to keep FTS index in sync
    execute <<-SQL
      CREATE TRIGGER postal_codes_ai AFTER INSERT ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(rowid, postal_code, name_km, name_en)
        VALUES (new.id, new.postal_code, new.name_km, new.name_en);
      END;
    SQL

    execute <<-SQL
      CREATE TRIGGER postal_codes_ad AFTER DELETE ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(postal_codes_fts, rowid, postal_code, name_km, name_en)
        VALUES ('delete', old.id, old.postal_code, old.name_km, old.name_en);
      END;
    SQL

    execute <<-SQL
      CREATE TRIGGER postal_codes_au AFTER UPDATE ON postal_codes BEGIN
        INSERT INTO postal_codes_fts(postal_codes_fts, rowid, postal_code, name_km, name_en)
        VALUES ('delete', old.id, old.postal_code, old.name_km, old.name_en);
        INSERT INTO postal_codes_fts(rowid, postal_code, name_km, name_en)
        VALUES (new.id, new.postal_code, new.name_km, new.name_en);
      END;
    SQL
  end
end
