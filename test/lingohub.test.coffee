assert    = require 'assert'
should    = require 'should'
mockfs    = require 'mock-fs'
fs        = require 'fs'
rewire    = require 'rewire'
path      = require('path')

#-------- rewired -------------
lingohub  = rewire '../lingohub'


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


  describe 'saveTranslationToFile', ->
    data = new Buffer('this is a test');

    beforeEach ->
      mockfs { }

    afterEach ->
      mockfs.restore()

    it "should exist saveTranslationToFile operation ", (done) ->
      lingohub.saveTranslationToFile.should.exist
      done()

    it "should be able to save to file data if path is provided ", (done) ->
      mockfs { }
      saveToPath = "/d1/d2/d3/test.i18n.json"
      lang = "es";

      lingohub.saveTranslationToFile saveToPath, data, lang, (err, path) ->
        should.not.exist err
        path.should.equal saveToPath
        fs.readFile path, (err, rdata) ->
          should.not.exists err
          rdata.should.deepEqual data
          done()

    it "should be able to save to file data if path is provided and the destination file already exists", (done) ->
      saveToPath = "/d1/d2/d3/test.i18n.json"
      mockfs {"#{saveToPath}" : "existing data" }
      lang = "es";

      lingohub.saveTranslationToFile saveToPath, data, lang, (err, path) ->
        should.not.exist err
        path.should.equal saveToPath
        fs.readFile path, (err, rdata) ->
          should.not.exists err
          rdata.should.deepEqual data
          done()

    it "should be able to save to file data to default path ", (done) ->
      mockfs { }
      lang = "es";

      lingohub.saveTranslationToFile null, data, lang, (err, path) ->
        should.not.exist err
        path.should.equal "i18n/#{lang}.i18n.json"
        fs.readFile path, (err, rdata) ->
          should.not.exists err
          rdata.should.deepEqual data
          done()


  describe 'getTranslationFile operation', ->
    sampleAuth = {account: "myaccount", token: "mytoken"}
    sampleData = new Buffer('this is a test');
    project = "testproject"
    lang = "es"
    saveTo = "/mypath/i18.es.json"

    beforeEach ->
      mockfs { "#{auth_token_path}": JSON.stringify(sampleAuth) }

    afterEach ->
      mockfs.restore()

    it "should getTranslationFile return error on received error form API server ", (done) ->
      # set  a mockup which return 404
      clientMock =
        get: (address, args, callback) ->
          callback(null , {statusCode:804})

      lingohub.__set__ "client", clientMock

      lingohub.getTranslationFile project, lang, saveTo,  (err, rpath) ->
        should.exist err
        err.code.should.equal 804
        done()

    it "should save received data under right path", (done) ->
      clientMock =
        get: (address, args, callback) ->
          callback(sampleData , {statusCode:200})

      lingohub.__set__ "client", clientMock

      lingohub.getTranslationFile project, lang, saveTo,  (err, rpath) ->
        should.not.exist err
        saveTo.should.equal rpath
        fs.readFile rpath, (err, rdata) ->
          should.not.exists err
          rdata.should.deepEqual sampleData
          done()


  describe 'convertToPath tool lib', ->

    beforeEach ->
      mockfs { }

    afterEach ->
      mockfs.restore()

    it "should be there a function convertToPath", (done) ->
      lingohub.convertToPath.should.exist
      done()

    it "should return final path from original null", (done) ->
      lingohub.convertToPath null, "es", (err, rpath) ->
        should.not.exist err
        rpath.should.equal  "i18n/es.i18n.json";
        done()

    it "should return final path if the original path is an existing directory", (done) ->
      saveToPath = "/test/i18n"
      mockfs({"#{saveToPath}":{}})
      lingohub.convertToPath saveToPath, "es", (err, rpath) ->
        should.not.exist err
        rpath.should.equal  "/test/i18n/es.i18n.json";
        done()

    it "should return final path if the original path is non-existing file", (done) ->
      saveToPath = "/test/i18n.json"
      lingohub.convertToPath saveToPath, "es", (err, rpath) ->
        should.not.exist err
        rpath.should.equal  saveToPath
        done()

    it "should return final path if the original path is already existing file", (done) ->
      saveToPath = "/test/i18n.json"
      mockfs({"#{saveToPath}":"Existing content"})
      lingohub.convertToPath saveToPath, "es", (err, rpath) ->
        should.not.exist err
        rpath.should.equal  saveToPath
        done()

    it "should prepare missing direcotries on the path", (done) ->
      saveToPath = "/dir1/dir2/dir3/test/i18n.json"
      lingohub.convertToPath saveToPath, "es", (err, rpath) ->
        should.not.exist err
        rpath.should.equal saveToPath
        fs.stat "/dir1/dir2/dir3/test" , (err, stats) ->
          should.not.exist err
          stats.isDirectory().should.equal true
          done()

    it "should return error if it's not possible to create dir", (done) ->
      saveToPath = "/dir1/dir2/dir3/test/i18n.json"
      mockfs({"/dir1/dir2":"Existing content"}) #/dir1/dir2 is in fact existing file

      lingohub.convertToPath saveToPath, "es", (err, rpath) ->
        should.exist err
        done()
