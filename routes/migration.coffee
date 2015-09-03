module.exports = (express, mysqlPool)->
  migrateRouter = express.Router()

  handle_database = (req, res, request)->
    pool.getConnection (err, connection)->
      if err
        connection.release()
        res.json
          "code": 100
          "status": "Error in connection database"
      console.log "Connected as id #{connection.threadId}"
      connection.query request, (err, rows)->
        connection.release()
        if not err then res.json rows
      connection.on "error", (err)->
        res.json
          "code": 100
          "status": "Error in connection database"

  migrateRouter.route '/'
    .get (req, res)->
      res.render "migration"

    .post (req, res)->
      console.log req.query
      res.render "migration"


  return migrateRouter

