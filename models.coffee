path = require 'path'

class exports.Group
  @cache: {}
  @client: {}
  @get: (id, callback) ->
    if Group.cache[id]
      callback(Group.cache[id])
    else
      Group.client.getGroup({groupid: id}, (error, data) ->
        if error
          console.log "An error ocurred fetching a group.}"
        if data?.group? 
          g = new Group(data.group.name, data.group.id)
          callback(g)
      )
  constructor: (@name, @id) ->
    Group.cache[@id] = @
    @
    