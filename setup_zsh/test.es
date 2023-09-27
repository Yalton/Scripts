GET /truenas_directory_data/_search
{
    "size":7,
    "query": {
        "match" : {
            "message" : {
                "query" : "this is a test"
            }
        }
    }
}