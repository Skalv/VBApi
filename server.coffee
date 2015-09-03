express         = require "express"
app             = express()

swig            = require "swig"

config          = require './configs/db'

mysql           = require "mysql"
mongoose        = require "mongoose"
mongooseConnect = mongoose.connection


# Connect to mongo DB
mongoAdr = "mongodb://#{config.mongoHost}:#{config.mongoPort}/#{config.mongoDatabase}"
console.log mongoAdr
mongoose.connect mongoAdr
mongooseConnect.on 'err', console.error.bind(console, 'connection error:')
mongooseConnect.once 'open', (cb)=>
  console.log 'Connected to Mongo !'

# Connect to Mysql (VBulletin)
pool = mysql.createPool
  host: config.mysqlHost
  user: config.mysqlUser
  password: config.mysqlPassword
  database: config.mysqlDatabase
  debug: false

# Enable Swig
app.engine 'html', swig.renderFile
app.set 'view engine','html'
app.set 'views', __dirname + '/templates'
app.set 'view cache', false
swig.setDefaults cache: false

# Router
dashboard = require("./routes/dashboard")(express)
app.use '/', dashboard

threadRoutes = require("./routes/thread")(express, pool)
app.use '/thread', threadRoutes

userRoutes = require("./routes/user")(express, pool)
app.use '/user', userRoutes

# Start server
server = app.listen 3000, ->
  host = server.address().address
  port = server.address().port

  console.log "Magic happens on #{host}:#{port}"