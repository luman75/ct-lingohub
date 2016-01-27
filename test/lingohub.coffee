assert    = require 'assert'
lingohub  = require '../lingohub'
should    = require 'should'
mockfs    = require 'mock-fs'
fs        = require 'fs'

auth_token_path = lingohub.auth_token_path


describe "Mocking Fs tests", ->
  describe 'read operations', ->
    beforeEach ->
      mockfs {'/etc/passwd': "alamakota"}

    afterEach ->
      mockfs.restore()

    it "should be able to get content of fake file", (done) ->
      lingohub.testingFs "/etc/passwd", (err, data) ->
        should.not.exist(err)
        data.should.equal "alamakota"
        done()


describe 'Basic operations on lingohub', ->

  describe 'login operation', ->
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
    afterEach ->
      mockfs.restore()

    it "should exist projects operation ", (done) ->
      lingohub.projects.should.exist
      done()
