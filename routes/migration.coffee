config = require '../configs/db'
VB     = config.mysqlVBDB
DRUPAL = config.mysqlDRDB

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

  migrateFromDrupal = (nid)->
    # get thread from drupal.
    query = "SELECT *
    FROM #{DRUPAL}.drupal_node n"
    # Add teaser, summary, body
    query += "LEFT JOIN #{DRUPAL}.drupal_field_data_field_teaser t ON n.nid = t.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_body b ON n.nid = b.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_summary s ON n.nid = s.entity_id"



    LEFT JOIN #{DRUPAL}.drupal_field_data_field_games g ON n.nid = g.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_type ty ON n.nid = ty.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_chronique_type ct ON n.nid = ct.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_image_carousel ic ON n.nid = ic.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_image_thumbnail it ON n.nid = it.entity_id
    LEFT JOIN #{DRUPAL}.drupal_field_data_field_related_topics rt ON n.nid = rt.entity_id
    WHERE n.nid = #{nid};"

    requestDatabase(query).then((result)->
      console.log "success", result
    , (err)->
      console.log "Error !!!", err
    )

  migrateFromVB = (thread)->
    console.log "VB !", thread.threadid



  migrateRouter.route '/'
    .get (req, res)->
      res.render "migration/_form"

    .post (req, res)->
      # Get datas
      _forumId  = if req.body.forumId? then req.body.forumId else ""
      _nbThread = if req.body.nbThread? then req.body.nbThread else ""
      # Construct validation request
      query = "SELECT title
      FROM #{VB}.vb_forum as f
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
      query = "SELECT p.*
      FROM #{VB}.vb_thread t
      LEFT JOIN #{VB}.vb_post p ON p.threadid = t.threadid
      WHERE t.forumid = #{_forumId}
      AND t.firstpostid = p.postid
      ORDER BY t.threadid DESC"
      # If define add LIMIT
      if _nbThread isnt ""
        query += " LIMIT #{_nbThread}"
      # add ; to end of query...
      query += ";"
      requestDatabase(query).then((result)->
        for thread in result
          if thread.pagetext.indexOf("[dtopic]") > -1
            text = thread.pagetext
            nid = text.substring(text.lastIndexOf("|")+1, text.lastIndexOf("["))
            migrateFromDrupal nid
          else
            migrateFromVB thread
      , (err)->
        console.log err
      )
      res.render "migration/_pending",
        forumTitle: _forumTitle
        forumId: _forumId



  return migrateRouter

