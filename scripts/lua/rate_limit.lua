local req = request.load()
if req:headers("X-Krakend-Rate-Limit") == "true" or req:headers("X-RateLimit-Limit") ~= nil then
  response.status(429)
end
