
#                                               //
#        _____                                  //
#       / ___/___  ______   _____  _____        //
#       \__ \/ _ \/ ___/ | / / _ \/ ___/        //
#      ___/ /  __/ /   | |/ /  __/ /            //
#     /____/\___/_/    |___/\___/_/             //
#                                               //
#                                               //

require = __meteor_bootstrap__.require
# Colors = require "colors"
MongoDB = require "mongodb"
Future = require "fibers/future"

console.log(Meteor.settings)


#                                                        //
#         ___                               __           //
#        /   | ______________  __  ______  / /______     //
#       / /| |/ ___/ ___/ __ \/ / / / __ \/ __/ ___/     //
#      / ___ / /__/ /__/ /_/ / /_/ / / / / /_(__  )      //
#     /_/  |_\___/\___/\____/\__,_/_/ /_/\__/____/       //
#                                                        //
#                                                        //

Accounts.onCreateUser (options, user) ->
  user.type = "admin"
  user.karma = 50
  user.logins = 0
  user.profile = options.profile  if options.profile
  user

Meteor.users.allow
  insert: (userId, docs) ->
    out = undefined
    out = _.all(docs)  if Meteor.users.findOne(_id: userId).type is "admin"
    out

  update: (userId, docs, fields, modifier) ->
    _.all docs, (doc) ->
      if Meteor.users.findOne(_id: userId).type is "admin"
        doc
      else
        doc._id is userId

  remove: (userId, docs) ->
    if Meteor.users.findOne(_id: userId).type is "admin"
      _.all docs
    else
      false


#                                                         //
#           __  ___     __  __              __            //
#          /  |/  /__  / /_/ /_  ____  ____/ /____        //
#         / /|_/ / _ \/ __/ __ \/ __ \/ __  / ___/        //
#        / /  / /  __/ /_/ / / / /_/ / /_/ (__  )         //
#       /_/  /_/\___/\__/_/ /_/\____/\__,_/____/          //
#                                                         //
#                                                         //

mapper = (a) ->
  map = (if _.isArray(a) then a else [a])
  _.map map, (d) ->
    out = {}
    out.username = d.username
    out.id = d._id
    out

Meteor.methods

  aggregateOffers: ->
    tags = Offers.aggregate
      $project:
        tags: 1

  message: (text, selector, opt) ->
    message = {}
    involve = [Meteor.userId()]
    admin = false
    existing = undefined
    ID = undefined
    if selector is "toAdmins"
      admins = Meteor.users.find(type: "admin").fetch()
      involve.push _.pluck(admins, "_id")
      involve = _.flatten(involve)
      admin = true
    else if selector is "offer"
      user = Meteor.users.findOne(_id: opt)
      involve.push user._id
    from = mapper(Meteor.user())
    content =
      from: from
      message: text
      sent: Time.now()

    if selector is "reply"
      ID = opt
    else
      existing = Messages.findOne(
        involve:
          $all: involve

        admin: false
      )
      unless existing
        message =
          involve: involve
          admin: admin
          content: [content]
          lastSent: Time.now()
      else
        ID = existing._id
    console.log "New message", message
    if selector isnt "reply" and not existing
      Messages.insert message, (err, res) ->
        console.log "Error", err  if err
        console.log "Successfully sent message, motherfucker", res

    else
      Messages.update
        _id: ID
      ,
        $push:
          content: content
      , (err, res) ->
        console.log "Error", err  if err
        console.log "Successfully sent message, motherfucker", res


  editOffer: (type, opts) ->
    @unblock()
    opts ?= {}
    out = {}

    throw new Meteor.Error(400, "Offer name is too short")  if opts.name.length < 5

    for key of Offer
      out[key] = opts[key]

    out.owner = Meteor.userId()
    out.createdAt ?= Time.now()
    out.updatedAt = Time.now()

    if type is "insert"
      out.votes.push
        user: @userId
        exp: Date.now() * 10
      Offers.insert out
    else
      Offers.update
        owner: @userId
      ,
        $set: out

    tagName = _.pluck(out.tags, "name")
    existTags = []
    Tags.find().forEach (m) ->
      _.filter m.involves, (f)->
        unless _.find(existTags, (ex)->
          ex._id is m._id)
          existTags.push m

    for exist in existTags

      Tags.update
          _id: exist._id
          "involves.user": Meteor.userId()
        ,
          $unset: "involves.$": 1
      Tags.update
          _id: exist._id
        ,
          $pull: "involves": null

    Tags.update
        name: $in: tagName
      ,
        $push:
          involves:
            user: out.owner
            loc:
              lat: out.loc.lat
              long: out.loc.long
      ,
        multi: true

  updateUserColor: (color) ->
    prime = Color(color).setLightness(.4)
    comp = prime.setSaturation(.5).tetradicScheme()[1]
    desat = prime.setSaturation(.2)
    darken = (a) ->
      a.setLightness(.2).setSaturation(.6).toString()
    lighten = (a) ->
      a.setLightness(.8).setSaturation(.4).toString()

    Meteor.users.update
      _id: Meteor.userId()
      ,
        $set:
          colors:
            prime:
              light: lighten prime
              medium: prime.toString()
              dark: darken prime
            comp:
              light: lighten comp
              medium: comp.toString()
              dark: darken comp
            desat:
              light: desat.setLightness( .8 ).toString()
              medium: desat.setLightness( .5 ).toString()
              dark: desat.setLightness( .2 ).toString()

  updateUser: (email, username) ->
    users = Meteor.users.find().fetch()
    existing = _.reject(users, (d) ->
      d._id is Meteor.userId()
    )
    existingEmails = _.pluck(_.flatten(_.compact(_.pluck(existing, "emails"))), "address")
    existingUsernames = _.pluck(existing, "username")

    throw new Meteor.Error(400, "Email unavailable")  if _.contains(existingEmails, email)
    throw new Meteor.Error(400, "Username unavailable")  if _.contains(existingUsernames, username)

    set = $set:
      username: username
      emails: [
        address: email
        verified: false
      ]

    Meteor.users.update
      _id: Meteor.userId()
    , set, {}, (err) ->
      err  if err

  isAdmin: (id) ->
    type = Meteor.users.findOne(_id: id).type
    unless type is "admin"
      false
    else
      true


