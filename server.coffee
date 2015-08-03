express = require "express"
app     = express()

app.get "/", (req, res)->
  res.send 'hello world'

server = app.listen 3333, ->
  host = server.address().address
  port = server.address().port

  console.log "Magic happens on #{host}:#{port}"