return {
  {
    name = "2018-03-01-120000_init_ankama",
    up = [[
      CREATE TABLE IF NOT EXISTS tbl_ankama(
        id uuid,
        consumer_id uuid REFERENCES consumers (id) ON DELETE CASCADE,
        username text,
        created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('ankama_consumer_id_idx')) IS NULL THEN
          CREATE INDEX ankama_consumer_id_idx ON tbl_ankama(consumer_id);
        END IF;
      END$$;
    ]],
    down =  [[
      DROP TABLE tbl_ankama;
    ]]
  }
}
