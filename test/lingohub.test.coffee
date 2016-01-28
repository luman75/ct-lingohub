assert    = require 'assert'
should    = require 'should'
mockfs    = require 'mock-fs'
fs        = require 'fs'
rewire    = require 'rewire'
lingohub  = rewire '../lingohub'
path      = require('path')


auth_token_path = lingohub.auth_token_path

describe 'Basic operations on lingohub', ->
  describe 'login operation', ->
    beforeEach ->
      mockfs { "#{path.dirname(auth_token_path)}": {} } # create a directory structure on virtual file system for location of auth_token_paths

    afterEach ->
      mockfs.restore()

    it "should exist login operation ", (done) ->
      lingohub.login.should.exist
      done()

    it "should be able to login when there is no file auth_file ", (done) ->
      mockfs { }
      lingohub.login  "accountYY", "tokenXX", (err, data) ->
        should.not.exist(err);
        fs.readFile auth_token_path, {encoding:"utf-8"} , (err, data) ->
          should.not.exist err
          data = JSON.parse(data)
          data.should.deepEqual {"account": "accountYY", "token": "tokenXX"}
          done()

    it "should be able to login when there is already file with auth_token", (done) ->
      mockfs { "#{auth_token_path}": JSON.stringify({"account": "myaccount", "token": "mytoken"}) }
      lingohub.login  "accountYY", "tokenXX", (err, data) ->
        should.not.exist(err);
        fs.readFile auth_token_path, {encoding:"utf-8"} , (err, data) ->
          should.not.exist err
          data = JSON.parse(data)
          data.should.deepEqual {"account": "accountYY", "token": "tokenXX"}
          done()

  describe 'logout operation', ->
    beforeEach ->
      mockfs { "#{path.dirname(auth_token_path)}": {} } # create a directory structure on virtual file system for location of auth_token_paths

    afterEach ->
      mockfs.restore()

    it "should exist logout operation ", (done) ->
      lingohub.logout.should.exist
      done()

    it "should be able to logout when there is no file auth_file ", (done) ->
      mockfs { }
      lingohub.logout (err) ->
        should.not.exist(err);
        fs.readFile auth_token_path, {encoding:"utf-8"} , (err, data) ->
          err.code.should.equal "ENOENT"
          done()

    it "should be able to logout when there is already the auth_file ", (done) ->
      mockfs { "#{auth_token_path}": JSON.stringify({"account": "myaccount", "token": "mytoken"}) }
      lingohub.logout (err) ->
        should.not.exist(err);
        fs.readFile auth_token_path, {encoding:"utf-8"} , (err, data) ->
          err.code.should.equal "ENOENT"
          done()

  describe 'getLoginData operation', ->
    beforeEach ->
      mockfs { "#{path.dirname(auth_token_path)}": {} } # create a directory structure on virtual file system for location of auth_token_paths

    afterEach ->
      mockfs.restore()

    it "should exist getLoginData operation ", (done) ->
      lingohub.getLoginData.should.exist
      done()

    it "should generate error when there is no login data", (done) ->
      mockfs { }
      lingohub.getLoginData (err, authObj) ->
        err.code.should.equal "NoAuthData"
        should.not.exists authObj
        done()

    it "should generate error when there non-parsable data in auth_token_file", (done) ->
      mockfs { "#{auth_token_path}": "alamakota" }
      lingohub.getLoginData (err, authObj) ->
        err.code.should.equal "ParseAuthFile"
        should.not.exists authObj
        done()

    it "should provide data from auth_token file when there is no options provided", (done) ->
      sampleAuth={account: "myaccount", token: "mytoken"}
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }
      lingohub.getLoginData (err, authObj) ->
        should.not.exists err
        authObj.account.should.equal sampleAuth.account
        authObj.token.should.equal sampleAuth.token
        done()

    it "should prefer options auth records than file", (done) ->
      sampleAuth={account: "myaccount", token: "mytoken"}
      option = {account: "myaccountOption", token: "mytokenOption"}
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }
      lingohub.getLoginData option, (err, authObj) ->
        should.not.exists err
        authObj.account.should.equal option.account
        authObj.token.should.equal option.token
        done()

    it "should prefer option token than file", (done) ->
      sampleAuth={account: "myaccount", token: "mytoken"}
      option = {token: "mytokenOption"}
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }
      lingohub.getLoginData option, (err, authObj) ->
        should.not.exists err
        authObj.account.should.equal sampleAuth.account
        authObj.token.should.equal option.token
        done()

    it "should prefer option account than file", (done) ->
      sampleAuth={account: "myaccount", token: "mytoken"}
      option = {account: "myaccountOption"}
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }
      lingohub.getLoginData option, (err, authObj) ->
        should.not.exists err
        authObj.account.should.equal option.account
        authObj.token.should.equal sampleAuth.token
        done()

  describe 'projects operation', ->
    sampleAuth = {account: "myaccount", token: "mytoken"}

    beforeEach ->
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }

    afterEach ->
      mockfs.restore()

    it "should project return error on received error form API server ", (done) ->
      # set  a mockup which return 404
      clientMock =
        get: (address, args, callback) ->
          callback(null , {statusCode:804})

      lingohub.__set__ "client", clientMock

      lingohub.projects (err, data) ->
        should.exist err
        err.code.should.equal 804
        done()


    it "should pass token to projects ", (done) ->
      # set  a mockup which return 404
      clientMock =
        get: (address, args, callback) ->
          should.exist args
          args.parameters.auth_token.should.equal sampleAuth.token
          done()
      lingohub.__set__ "client", clientMock

      lingohub.projects (err, data) ->

