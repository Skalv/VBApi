module.exports = (express)->
  dashRouter = express.Router()

  dashRouter.route '/'
    .get (req, res)->
      res.render "dashboard",
        name: "Florent"


  return dashRouter