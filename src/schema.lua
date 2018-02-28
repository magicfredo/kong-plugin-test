local ANKAMA_APIS = {
  "avatar",
  "dofus-esport",
}

return {
    no_consumer = true,
    fields = {
        api_name = {
            type = "string",
            required = true,
            enum = ANKAMA_APIS
        },
        jwt_secret_public = {
            type = "string"
        },
        jwt_secret_private = {
            type = "string"
        }
    }
}