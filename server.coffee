express = require "express"
app     = express()

swig    = require "swig"

config  = require './configs/db'

mysql   = require "mysql"


pool = mysql.createPool
  host: config.host
  user: config.user
  password: config.password
  database: config.database
  debug: false

app.engine 'html', swig.renderFile
app.set 'view engine','html'
app.set 'views', __dirname + '/templates'
app.set 'view cache', false
swig.setDefaults cache: false


app.get "/", (req, res)->
  res.send 'hello world'

dashboard = require("./routes/dashboard")(express)
app.use '/dashboard', dashboard

threadRoutes = require("./routes/thread")(express, pool)
app.use '/thread', threadRoutes

userRoutes = require("./routes/user")(express, pool)
app.use '/user', userRoutes

server = app.listen 3000, ->
  host = server.address().address
  port = server.address().port

  console.log "Magic happens on #{host}:#{port}"