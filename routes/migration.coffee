module.exports = (express, mysqlPool)->
  migrateRouter = express.Router()
  _forumId      = null
  _nbThread     = null
  _forumTitle   = null

  requestDatabase = (query)->
    Request = new Promise (resolve, reject)->
      mysqlPool.getConnection (err, connection)->
        if err
          connection.release()
          reject "Error in connection database"
        connection.query query, (err, rows)->
          connection.release()
          if not err
            resolve rows
        connection.on "error", (err)->
          reject "Error in connection database"
    return Request

  migrateRouter.route '/'
    .get (req, res)->
      res.render "migration/_form"

    .post (req, res)->
      # Get datas
      _forumId  = if req.body.forumId? then req.body.forumId else ""
      _nbThread = if req.body.nbThread? then req.body.nbThread else ""
      # Construct validation request
      query = "SELECT title
      FROM vb_forum as f
      WHERE f.forumid = #{_forumId}
      ;"
      # Request and display result on validation page
      requestDatabase(query).then((result)->
        _forumTitle = result[0].title
        res.render "migration/_validation",
          forumTitle: _forumTitle
          forumId: _forumId
      , (err)->
        console.log err
      )

  migrateRouter.route '/migrate'
    # Start migration
    .get (req, res)->
      # Construct query
      query = "SELECT *
      FROM vb_thread
      WHERE forumid = #{_forumId}
      ORDER BY threadid DESC"
      # If define add LIMIT
      if _nbThread isnt ""
        query += " LIMIT #{_nbThread}"

      requestDatabase(query).then((result)->
        console.log "result", result.length
      , (err)->
        console.log err
      )
      res.render "migration/_pending",
        forumTitle: _forumTitle
        forumId: _forumId



  return migrateRouter

