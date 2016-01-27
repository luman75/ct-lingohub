#
# lingohub rest library
#
#
#
fs = require 'fs'
Client = require('node-rest-client').Client;
client = new Client();
expandTilde = require('expand-tilde');
_ = require 'underscore'

authObj =
  account :null
  token : null

auth_token_path=expandTilde("~/.ct-import.auth")

#--------------------------------------------------
# this operation is used to save credential token
login = (account, token, callback) ->
  authObj =
    account : account
    token : token

  try
    fs.writeFileSync auth_token_path, JSON.stringify(authObj, null, 4)
  catch e
    callback(e); return

  callback(e)


#--------------------------------------------------
# this logout user form system by removing ~/.ct-import.auth file
logout = (callback) ->
  err = null
  try
    fs.unlinkSync(auth_token_path)
  catch e
    if e.code is not "ENOENT"
      err = e

  callback?(err)

#--------------------------------------------------
# this function return login data object based on auth_token file or options parameter
# @params
#   options - object {account, token}
#   callback(err, data) where data ia an object containing {account, token}
getLoginData = (options, callback) ->
  if _.isFunction options
    callback = options
    options = {}

  authObj = {}
  fs.readFile auth_token_path, {encoding:"utf-8"} , (err, fileRecord) =>
    data = {}
    # when there is a auth file read it. Maybe we wil us it later.
    if !err
      try
        data = JSON.parse(fileRecord)
      catch e
        # when we can't parse auth_token file it means we need to report that to user
        callback({code:'ParseAuthFile' , message:"I can't parse #{auth_token_path} file. It should be pure json file. Correct it or remove it. "})
        return

    if data.account?
      authObj.account = data.account

    if data.token?
      authObj.token = data.token

    # if there are options we override the settings from file
    if options.account?
      authObj.account = options.account

    if options.token?
      authObj.token = options.token

    if authObj.account? and authObj.token?
      callback(null, authObj)
    else
      callback({code:"NoAuthData", message:"There is no authorization data provided. You need to login first or provide --token and --account option to the commnad."})



#--------------------------------------------------
# this function list of projects for currently logged in user
# @params
#   callback(err, data) where data ia an object containing information about all projects in the account
projects = (options, callback)->
  if _.isFunction options
    callback=options
    options={}

  getLoginData options (err, authObj) ->
    if err
      callback(err)
    else
      args =
        parameters:
          auth_token: authObj.token

      client.get "https://api.lingohub.com/v1/projects.json", args, (data, response) ->
        if response.statusCode != 200
          callback({code:response.statusCode,  message:"Error. Status Code: #{response.statusCode} #{response.statusMessage}"})
        else
          callback(null, data)


#--------------------------------------------------
# this function returns full details about project
# @params
#   project - name of the procject in lingohub
#   callback(err, data) - error or project object
getProject = (project, callback) ->
  if !auth_token? or !account?
    callback({message:"You need to login first"})
    return

  args =
    path:
      account: account
      project: project
    parameters:
      auth_token: auth_token

  client.get "https://api.lingohub.com/v1/${account}/projects/${project}.json", args, (data, response) ->
    if response.statusCode != 200
      callback({code:response.statusCode,  message:"Error. Status Code: #{response.statusCode} #{response.statusMessage}"})
    else
      callback(null, data)

#--------------------------------------------------
# function returns current list of project locales or error
# @params
#     project
#     callback(err, locales) - returns errors or array of of locales
getProjectLocales = (project, callback) ->
  getProject project, (err, data) ->
    if err
      callback(err)
    else
      callback(null, data.project_locales)


#--------------------------------------------------
# get the file from lingohub
# @params
#   project   - name of the project
#   lang      - lang code like es, en or pt-BR
#   saveTo [optional] - path where the data should be saved, if the parameter is not available we won't save
#   callback(err, data) - return error or buffer
getFile = (project, lang, saveTo, callback) ->
  if !auth_token? or !account?
    callback("You need to login first")
    return

  args =
    path:
        account: account
        project: project
        lang: lang
    parameters:
      auth_token: auth_token

  client.get "https://api.lingohub.com/v1/${account}/projects/${project}/resources/${lang}.i18n.json", args, (data, response) ->
    if response.statusCode != 200
      callback({code:response.statusCode,  message:"Error. Status Code: #{response.statusCode} #{response.statusMessage}"})
    else
      callback(null, data)


#--------------------------------------------------
# upload an i18n file from a path which is a file containing i18n text in lang
# @params
#   project - project name
#   path    - path where the data file should be read from
#   lang    - language code
#   callback(err) - return error on problems enountered
uploadFile = (project, path, lang, callback) ->
  if !auth_token? or !account?
    callback("You need to login first")
    return

  args =
    path:
      account: account
      project: project
      lang: lang
    parameters:
      auth_token: auth_token

  client.get "https://api.lingohub.com/v1/${account}/projects/${project}/resources/${lang}.i18n.json", args, (data, response) ->
    if response.statusCode != 200
      callback({code:response.statusCode,  message:"Error. Status Code: #{response.statusCode} #{response.statusMessage}"})
    else
      callback(null, data)



testingFs = (path, callback) ->
  fs.readFile path, {encoding:"utf-8"} , (err, data) =>
    if (err)
      callback({err:err})

    callback(null, data);



#--------------------------------------------------
exports.login = login
exports.logout = logout
exports.getLoginData = getLoginData
exports.projects = projects
exports.getProject = getProject
exports.getProjectLocales = getProjectLocales
exports.getFile = getFile
exports.uploadFile = uploadFile
exports.testingFs = testingFs
exports.auth_token_path = auth_token_path
