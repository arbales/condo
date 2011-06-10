Nodevore = require('nodevore').Nodevore
Growl = require 'Growl' 
get = require 'get'
mkdirp = require('mkdirp').mkdirp
env = process.env
path = require 'path'   
models = require("./models")      
Group = models.Group
                
# TODO: gross.    
userProfileImage = (hash, callback) ->
  path.exists "#{process.env.HOME}/.condo/users/#{hash.username}.png", (exists) ->
    if exists is true
      callback("#{process.env.HOME}/.condo/users/#{hash.username}.png")
    else
      download = new get {uri: hash.img.replace("https","http")}
      download.toDisk "#{process.env.HOME}/.condo/users/#{hash.username}.png", (error) =>              
        if error
          console.log "Failed to get user image: #{err}"
        callback("#{process.env.HOME}/.condo/users/#{hash.username}.png")
        
class exports.Application  
  cursor: false
  constructor: ->    
    console.log "Connecting to Convore..."
    @client = new Nodevore({ username : env.CONVORE_USERNAME,  password : env.CONVORE_PASSWORD})
    @username = env.CONVORE_USERNAME
    @login()


  login: ->
    @client.verifyAccount (error, payload) =>  
      if error
        console.log(error)
        process.exit(1)
      else  
        console.log "Condo is now listening for awesome shit on Convore..."
        Group.client = @client
        @listen()           
        mkdirp "#{process.env.HOME}/.condo/users", 0755, (error) =>
          unless error               
            download = new get {uri: payload.img.replace("https","http")}
            download.toDisk "#{process.env.HOME}/.condo/me.png", (error) =>              
              if error
                console.log "Failed to get user image: #{err}"
              Growl.notify("You'll receive notifications on any mentions.", { title: "Welcome to Convore", image: "~/.condo/me.png" })   

  # Hmm, but it works.
  receive: (data) ->    
    if not @cursor and data._id
      console.log "Acquired cursor..."
      @client.hangup()
      @cursor = data._id 
      @listen() 
    console.log "Message received..."  
    switch data.kind
      when 'message' and data.user.username isnt @username
        console.log data
        Group.get data.group, (group) =>
          userProfileImage data.user, (image) =>   
            Growl.notify(data.message, {title: "#{group.name}/#{data.topic.name}", image: image})

      # When does it ever return this? Boggle.
      when 'mention'
        Group.get data.group, (group) =>
          userProfileImage data.user, (image) =>  
            Growl.notify(data.message, {title: "#{data.username} mentioned you in #{data.topic.name}", image: image})
      else
        true
        #console.log ""
    
    

  listen: -> 
    if @cursor isnt false
      @client.live {cursor: @cursor}, (error, payload) =>  
        if error
          console.log "Error: #{error}"
        else
          @receive item for item in payload.messages
    else          
      @client.live (error, payload) => 
        if error
          console.log "Error: #{error}"
        else
          @receive item for item in payload.messages
