local ankama_apis = {
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
        ankama_api = {
            type = "string",
            enum = ankama_apis
        },
        jwt_rsa_private_key = {
            type = "string"
        }
    }
}