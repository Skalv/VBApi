
module.exports = (express, connection)->
  apiRouter = express.Router()

  apiRouter.route "/thread"

    .get (req, res)->
      connection.connect()

      connection.query "SELECT * FROM vb_thread", (err, rows, fields)->
        if err then res.send err
        res.json rows

      connection.end()

    .post (req, res)->
      res.send ""

  apiRouter.route "/thread/:id"

    .get (req, res)->
      id = req.params.id

      connection.connect()

      query = "SELECT *
        FROM vb_thread as t
        WHERE t.threadid = #{id}"

      connection.query query, (err, rows, fields)->
        if err then res.send err
        res.json rows

      connection.end()


  return apiRouter
