config  = require '../configs/db'
VB      = config.mysqlVBDB
DRUPAL  = config.mysqlDRDB
User    = require '../models/user'
Moment  = require 'moment'

module.exports = (express, mysqlPool)->

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

  getUserQuery = ->
    query = "SELECT u.*, ca.filename, ca.dateline, ug.usertitle, uf.field2, uf.field5
    FROM #{VB}.vb_user u"
    # Add avatar
    query += " LEFT JOIN #{VB}.vb_customavatar ca ON ca.userid = u.userid"
    # Link Group
    query += " LEFT JOIN #{VB}.vb_usergroup ug ON ug.usergroupid = u.usergroupid"
    # User profil
    query += " LEFT JOIN #{VB}.vb_userfield uf ON uf.userid = u.userid"
    # Query end
    query += " ORDER BY u.userid
    LIMIT 10
    ;"

    return query


  migrateRouter = express.Router()

  migrateRouter.route '/'
    .get (req, res)->
      res.render "migration/_user_validation"

  migrateRouter.route '/migrate'
    .get (req, res)->
      query = getUserQuery()
      requestDatabase(query).then((result)->
        for user in result
          newUser = new User
          newUser.local.userid      = user.userid
          newUser.local.usergroupid = user.usergroupid
          newUser.local.username    = user.username
          newUser.local.password    = user.password
          newUser.local.email       = user.email
          newUser.local.salt        = user.salt
          newUser.fromVB            = true
          newUser.avatar.filename   = user.filename
          newUser.avatar.dateline   = user.dateline
          newUser.group.usertitle   = user.usertitle
          newUser.profil.ville      = user.field2
          newUser.profil.team       = user.field5

          newUser.save (err)->
            if err then return console.log "error on mongo save : #{err}"
            console.log "success saving user !"
        res.json {"success": true}
      , (err)->
        res.json {"err": err}
      )


  return migrateRouter

