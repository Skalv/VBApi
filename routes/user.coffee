
module.exports = (express, pool)->
  userRouter = express.Router()

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

  userRouter.route "/"
    .get (req, res)->
      request = "SELECT *
        FROM vb_user"

      handle_database req, res, request

    .post (req, res)->
      res.send ""

  userRouter.route "/:id"
    .get (req, res)->
      id = req.params.id

      request = "SELECT *
        FROM vb_user as u
        WHERE u.userid = #{id}"

      handle_database req, res, request


  return userRouter