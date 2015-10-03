Mongoose = require "mongoose"
Schema   = Mongoose.Schema
ObjectId = Schema.ObjectId
Slug     = require "slug"

# Enum
genres = ["guide","news","test","notification", "topic"]
states = ["writing","layout","correction","published","waitPublish"]
# Schema
ArticleSchema = new Schema
  title:         {type: String, required: true}
  slug:          {type: String}
  body:          {type: String}
  bodyHTML:      {type: String}
  description:   {type: String, required: true}
  thumbnails:
    alt:         {type: String}
    filename:    {type: String}
    webPath:     {type: String}
    path:        {type: String}
  genre:         {type: String, enum: genres, required: true}
  section:       {type: String, required: true}
  author:        {type: Number}
  contributors:[
    userId:      ObjectId
    action:      String
  ]
  dateCreated:   { type: Date, default: Date.now }
  dateUpdated:   { type: Date, default: Date.now }
  datePublished: Date
  state:         { type: String, enum: states }
  keywords:      [String]
  fromV2:        {type: Boolean}

# Middlewares
ArticleSchema.pre 'save', (next)->
  @slug = Slug @title
  next()

module.exports = Mongoose.model 'Article', ArticleSchema