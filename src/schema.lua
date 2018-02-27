local ANKAMA_APIS = {
  "avatar",
  "dofus-esport",
}

return {
    no_consumer = true,
    fields = {
        authorization = {
            type = "boolean",
            default = true
        },
        api_name = {
            type = "string",
            required = true,
            enum = ANKAMA_APIS
        },
        jwt_rsa_private_key = {
            type = "string"
        }
    }
}