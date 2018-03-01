return {
  {
    name = "2018-03-01-120000_init_ankama",
    up = [[
       CREATE TABLE IF NOT EXISTS tbl_ankama(
        id uuid,
        consumer_id uuid,
        username text,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON tbl_ankama(username);
      CREATE INDEX IF NOT EXISTS ankama_consumer_id_idx ON tbl_ankama(consumer_id);
    ]],
    down = [[
      DROP TABLE tbl_ankama;
    ]]
  }
}
