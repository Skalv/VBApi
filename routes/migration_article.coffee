config  = require '../configs/db'
VB      = config.mysqlVBDB
DRUPAL  = config.mysqlDRDB
Article = require '../models/article'
Moment  = require 'moment'
_       = require 'underscore'

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

  migrateFromDrupal = (nids)->
    Migrate = new Promise (resolve, reject)->
      if nids.length is 0 then resolve true; return
      # get thread from drupal.
      query = "SELECT n.type, n.title, n.created, n.changed, n.uid,
      t.field_teaser_value as teaser, b.field_body_value as body, s.field_summary_value as summary,
      do.sitename as section,
      ic.field_image_carousel_alt as carousel_alt, fmc.filename as carousel_filename, fmc.uri as carousel_uri,
      it.field_image_thumbnail_alt as thumbnail_alt, fmt.filename as thumbnail_filename, fmt.uri as thumbnail_uri"
      query += " FROM #{DRUPAL}.drupal_node n"
      # Add teaser, summary, body
      query += " LEFT JOIN #{DRUPAL}.drupal_field_data_field_teaser t ON n.nid = t.entity_id
      LEFT JOIN #{DRUPAL}.drupal_field_data_field_body b ON n.nid = b.entity_id
      LEFT JOIN #{DRUPAL}.drupal_field_data_field_summary s ON n.nid = s.entity_id"
      # Get sections.
      query += " LEFT JOIN #{DRUPAL}.drupal_field_data_field_games g ON n.nid = g.entity_id
      LEFT JOIN #{DRUPAL}.drupal_domain do ON g.field_games_value = do.domain_id"
      # Get type
      # query += " LEFT JOIN #{DRUPAL}.drupal_field_data_field_type ty ON n.nid = ty.entity_id"
      # Get images
      query += " LEFT JOIN #{DRUPAL}.drupal_field_data_field_image_carousel ic ON n.nid = ic.entity_id
      LEFT JOIN #{DRUPAL}.drupal_field_data_field_image_thumbnail it ON n.nid = it.entity_id
      LEFT JOIN #{DRUPAL}.drupal_file_managed fmc ON fmc.fid = ic.field_image_carousel_fid
      LEFT JOIN #{DRUPAL}.drupal_file_managed fmt ON fmt.fid = it.field_image_thumbnail_fid"
      ###
      LEFT JOIN #{DRUPAL}.drupal_field_data_field_related_topics rt ON n.nid = rt.entity_id
      ###
      query += " WHERE n.nid IN (#{nids.toString()});"
      console.log "query", query
      # requesting
      console.log "start querying DP", nids.length
      requestDatabase(query).then((result)->
        console.log "drupal data recovered"
        articleNotSave = []
        _.reduce(result, (previousPromise, articleDP)->
          previousPromise.then(->
            Save = new Promise (resolve, reject)->
              # Define Thumb URI
              realThumbUri = "/img/defaultThumb.jpg"
              if articleDP.thumbnail_uri?
                uri = articleDP.thumbnail_uri
                cleanThumbUri = uri.substring(uri.lastIndexOf("://")+2)
                realThumbUri = "http://portail.fureur.org/sites/default/files#{cleanThumbUri}"

              # Define description
              if articleDP.teaser?
                description = articleDP.teaser
              else if articleDP.summary?
                description = articleDP.summary
              else
                description = ""
              # Create Article
              newArticle = new Article
              newArticle.title               = articleDP.title
              newArticle.bodyHTML            = articleDP.body
              newArticle.description         = description
              newArticle.genre               = articleDP.type
              newArticle.section             = articleDP.section
              newArticle.state               = "published"
              newArticle.author              = articleDP.uid
              newArticle.thumbnails.filename = articleDP.thumbnail_filename
              newArticle.thumbnails.alt      = articleDP.thumbnail_alt
              newArticle.thumbnails.webPath  = realThumbUri
              newArticle.dateCreated         = Moment.unix(articleDP.created).format()
              newArticle.dateUpdated         = Moment.unix(articleDP.changed).format()
              newArticle.Published           = articleDP.created
              newArticle.fromV2              = true
              # Save article
              newArticle.save (err)->
                if err
                  console.log "error on mongo save : ", articleDP.title
                  articleNotSave.push articleDP
                  resolve true
                resolve true

            return Save
          )
        , Promise.resolve()).then(->
          console.log articleNotSave.length, " articles not save !"
          return resolve true
        )
      , (err)->
        console.log "Error !!!", err
        reject true
      )

    return Migrate

  migrateFromVB = (thread)->
    Migrate = new Promise (resolve, reject)->
      console.log "VB !", thread.threadid
      resolve true
    return Migrate

  migrateRouter.route '/'
    .get (req, res)->
      query = "SELECT title, forumId
      FROM #{VB}.vb_forum
      ;"
      requestDatabase(query).then((result)->
        res.render "migration/_form",
          forums: result
      )

    .post (req, res)->
      # Get datas
      _forumId  = if req.body.forumId? then req.body.forumId else ""
      _nbThread = if req.body.nbThread? then req.body.nbThread else ""
      # Construct validation request
      query = "SELECT COUNT(*) as nbPost
      FROM #{VB}.vb_thread t
      LEFT JOIN #{VB}.vb_post p ON p.threadid = t.threadid
      AND t.firstpostid = p.postid
      WHERE t.forumid = #{_forumId}
      ;"
      # Request and display result on validation page
      requestDatabase(query).then((result)->
        res.render "migration/_validation",
          nbPost: result[0]["nbPost"]
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
        console.log "GO Articles !", result.length

        DPColArticles = []
        VBColArticles = []
        _.each result, (article)->
          if article.pagetext.indexOf("[dtopic]") > -1
            text = article.pagetext
            nid = text.substring(text.lastIndexOf("|")+1, text.lastIndexOf("["))
            DPColArticles.push nid
          else
            VBColArticles.push article
        console.log "count", DPColArticles.length, VBColArticles.length
        console.log "Migrate from DP"
        migrateFromDrupal(DPColArticles).then(->
          console.log "DRUPAL migration end !"
          return migrateFromVB VBColArticles
        ).then(->
          console.log "VB Migration end !"
          return Promise.resolve()
        ).then(->
          console.log 'FINI'
        ).catch (err)->
          console.log "ERROR during migration", err

      , (err)->
        console.log err
      )

      res.render "migration/_pending",
        forumTitle: _forumTitle
        forumId: _forumId



  return migrateRouter

