express = require "express"
app     = express()

config  = require './configs/db'

mysql   = require "mysql"


pool = mysql.createPool
  host: config.host
  user: config.user
  password: config.password
  database: config.database
  debug: false

app.get "/", (req, res)->
  res.send 'hello world'

threadRoutes = require("./routes/thread")(express, pool)
app.use '/thread', threadRoutes

userRoutes = require("./routes/user")(express, pool)
app.use '/user', userRoutes

server = app.listen 3333, ->
  host = server.address().address
  port = server.address().port

  console.log "Magic happens on #{host}:#{port}"