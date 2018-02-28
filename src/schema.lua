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
        jwt_public_key = {
            type = "string"
        },
        jwt_private_key = {
            type = "string"
        }
    }
}