express = require "express"
app     = express()

config  = require "./configs/db"

mysql   = require "mysql"


connection = mysql.createConnection({
    host:     config.host
    user:     config.user
    password: config.password
    database: config.database
  })


app.get '/test', (req, res)->

  connection.connect()

  connection.query "SELECT * FROM vb_thread as t WHERE t.threadid = 7", (err, rows, fields)->
    if err then res.send err
    console.log rows[0]
    res.send ""

  connection.end()

app.get "/", (req, res)->
  res.send 'hello world'
  console.log config

server = app.listen 3333, ->
  host = server.address().address
  port = server.address().port

  console.log "Magic happens on #{host}:#{port}"