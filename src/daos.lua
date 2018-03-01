local SCHEMA = {
  primary_key = {'id'},
  table = 'tbl_ankama',
  cache_key = {'ak_cache_key'},
  fields = {
    id = {type = 'id', dao_insert_value = true},
    created_at = {type = 'timestamp', immutable = true, dao_insert_value = true},
    consumer_id = {type = 'id', required = true, foreign = 'consumers:id'},
    username = {type = 'string', required = true, unique = true }
  },
}

return {tbl_ankama = SCHEMA}
