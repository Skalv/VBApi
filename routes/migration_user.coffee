config  = require '../configs/db'
VB      = config.mysqlVBDB
DRUPAL  = config.mysqlDRDB
User    = require '../models/user'
Moment  = require 'moment'
_       = require 'underscore'
RSVP    = require 'rsvp'

module.exports = (express, mysqlPool)->

  saveInMongo = (vbUser)->
    Save = new RSVP.Promise (resolve, reject)->
      newUser = new User
      newUser.local.userid      = vbUser.userid
      newUser.local.usergroupid = vbUser.usergroupid
      newUser.local.username    = vbUser.username
      newUser.local.password    = vbUser.password
      newUser.local.email       = vbUser.email
      newUser.local.salt        = vbUser.salt
      newUser.fromVB            = true
      newUser.avatar.filename   = vbUser.filename
      newUser.avatar.dateline   = vbUser.dateline
      newUser.group.usertitle   = vbUser.usertitle
      newUser.profil.ville      = vbUser.field2
      newUser.profil.team       = vbUser.field5

      newUser.save (err)->
        if err
          reject err
        else
          console.log newUser.local.username, "saved !"
          resolve true

    return Save

  requestDatabase = (query)->
    Request = new RSVP.Promise (resolve, reject)->
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
    ;"

    return query

  migrateRouter = express.Router()

  migrateRouter.route '/'
    .get (req, res)->
      requestDatabase("SELECT COUNT(*) as nbuser FROM #{VB}.vb_user;").then (result)->
        res.render "migration/_user_validation",
          nbuser: result[0]["nbuser"]


  migrateRouter.route '/migrate'
    .get (req, res)->
      query = getUserQuery()
      requestDatabase(query).then((result)->
        console.log "GO !", result.length
        i = 1
        _.reduce(result, (previousPromise, user)->
          previousPromise.then(->
            console.log i
            i += 1
            #return RSVP.Promise.resolve()
            return saveInMongo(user)
          , (err)->
            console.log "error in mongo save : ", err
          )
        , Promise.resolve()).then(()->
          console.log "FINI"
        )
      , (err)->
        console.log "ERROR", err
      )
      res.render "migration/_pending"


  return migrateRouter

