config  = require '../configs/db'
VB      = config.mysqlVBDB
DRUPAL  = config.mysqlDRDB

module.exports = (express, mysqlPool)->
  dashRouter = express.Router()

  dashRouter.route '/'
    .get (req, res)->
      res.render "dashboard",
        name: "Florent"

  return dashRouter