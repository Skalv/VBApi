Mongoose = require "mongoose"
Schema   = Mongoose.Schema
ObjectId = Schema.ObjectId

# Schema
UserSchema = new Schema
  local:
    name:        type: String
    userid:      type: Number, unique: true
    usergroupid: type: Number
    username:    type: String
    password:    type: String, select: false
    email:       type: String
    salt:        type: String, select: false
  facebook:
    id:          type: String
    token:       type: String
    email:       type: String
    name:        type: String
  twitter:
    id:          type: String
    token:       type: String
    displayName: type: String
    username:    type: String
  fromVB:        type: Boolean
  avatar:
    filename:    type: String
    dateline:    type: String
  group:
    usertitle:   type: String
  profil:
    ville:       type: String
    team:        type: String

module.exports = Mongoose.model 'User', UserSchema