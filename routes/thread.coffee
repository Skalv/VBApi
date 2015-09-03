
module.exports = (express, pool)->
  apiRouter = express.Router()

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
        if not err
          res.json rows
      connection.on "error", (err)->
        res.json
          "code": 100
          "status": "Error in connection database"

  apiRouter.route "/"
    .get (req, res)->
      request = "SELECT *
        FROM vb_thread
        LIMIT 10"

      handle_database req, res, request

    .post (req, res)->
      res.send ""

  apiRouter.route "/:id"
    .get (req, res)=>
      id = req.params.id

      request = "SELECT *
        FROM vb_thread as t
        WHERE t.threadid = #{id}"

      handle_database req, res, request


  return apiRouter