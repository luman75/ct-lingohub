var fs = require('fs');
var Client = require('node-rest-client').Client;
var client = new Client();
var expandTilde = require('expand-tilde');
var _ = require('underscore');
var mkdirp = require('mkdirp');
var Path = require('path');
var request = require('request');
var async = require('async');

var authObj = {
    account: null,
    token: null
};

var auth_token_path = expandTilde("~/.ct-import.auth");

//#--------------------------------------------------
//# this operation is used to save credential token
login = function(account, token, callback) {
    var e;
    authObj = {
        account: account,
        token: token
    };
    try {
        fs.writeFileSync(auth_token_path, JSON.stringify(authObj, null, 4));
    } catch (_error) {
        e = _error;
        callback(e);
        return;
    }
    return callback(e);
};

//#--------------------------------------------------
//# this logout user form system by removing ~/.ct-import.auth file
logout = function(callback) {
    var e, err;
    err = null;
    try {
        fs.unlinkSync(auth_token_path);
    } catch (_error) {
        e = _error;
        if (e.code === !"ENOENT") {
            err = e;
        }
    }
    return typeof callback === "function" ? callback(err) : void 0;
};


//#--------------------------------------------------
//# this function return login data object based on auth_token file or options parameter
//# @params
//#   options - object {account, token}
//#   callback(err, data) where data ia an object containing {account, token}
getLoginData = function(options, callback) {
    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }
    authObj = {};
    return fs.readFile(auth_token_path, {
        encoding: "utf-8"
    }, function(err, fileRecord) {
            var data, e;
            data = {};
            if (!err) {
                try {
                    data = JSON.parse(fileRecord);
                } catch (_error) {
                    e = _error;
                    callback({
                        code: 'ParseAuthFile',
                        message: "I can't parse " + auth_token_path + " file. It should be pure json file. Correct it or remove it. "
                    });
                    return;
                }
            }
            if (data.account != null) {
                authObj.account = data.account;
            }
            if (data.token != null) {
                authObj.token = data.token;
            }
            if (options.account != null) {
                authObj.account = options.account;
            }
            if (options.token != null) {
                authObj.token = options.token;
            }
            if ((authObj.account != null) && (authObj.token != null)) {
                return callback(null, authObj);
            } else {
                return callback({
                    code: "NoAuthData",
                    message: "There is no authorization data provided. You need to login first or provide --token and --account option to the commnad."
                });
            }
        }
    );
};

//#--------------------------------------------------
//# this function list of projects for currently logged in user
//# @params
//#   callback(err, data) where data ia an object containing information about all projects in the account
projects = function(options, callback) {
    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        var args;
        if (err) {
            return callback(err);
        } else {
            args = {
                parameters: {
                    auth_token: authObj.token
                }
            };
            return client.get("https://api.lingohub.com/v1/projects.json", args, function(data, response) {
                if (response.statusCode !== 200) {
                    return callback({
                        code: response.statusCode,
                        message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
                    });
                } else {
                    var output;

                    if (options.json){
                        output=data;
                    }else{
                        output = [];
                        if (data.members && _.isArray(data.members)){
                            data.members.forEach(function(currentValue){
                                if (_.isObject(currentValue) && currentValue.title){
                                    output.push(currentValue.title)
                                }
                            });
                        }
                    }

                    return callback(null, output);
                }
            });
        }
    });
};

//#--------------------------------------------------
//# this function returns full details about project
//# @params
//#   project - name of the procject in lingohub
//#   callback(err, data) - error or project object
getProject = function(project, options, callback) {
    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        if (err) {
            return callback(err);
        } else {

            var args = {
                path: {
                    account: authObj.account,
                    project: project
                },
                parameters: {
                    auth_token: authObj.token
                }
            };

            client.get("https://api.lingohub.com/v1/${account}/projects/${project}.json", args, function (data, response) {
                if (response.statusCode !== 200) {
                    return callback({
                        code: response.statusCode,
                        message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
                    });
                } else {
                    return callback(null, data);
                }
            });
        }
    });
};

//#--------------------------------------------------
//# function returns current list of project locales or error
//# @params
//#     project
//#     callback(err, locales) - returns errors or array of of locales
getProjectLocales = function(project, options, callback) {
    return getProject(project, options, function(err, data) {
        if (err) {
            return callback(err);
        } else {
            return callback(null, data.project_locales);
        }
    });
};

//#--------------------------------------------------
//# convert path to actual file path. The algorithm depends on if path param is a directory or not
//# it should
//# @params
//#     path - proposed path might be null then we go to default
//#     lang - current lang we are processing
//#     callback(err, path) - returns the outcome of this function
convertToPath = function(path, lang, callback){
    if (typeof path === "undefined" || path === null){
        path = "i18n/" + lang + ".i18n.json";
    }
    var basepath;
    if (path.substr(path.length-1,1) == "/"){
        basepath = path;
    }else{
        basepath = Path.dirname(path);
    }

    mkdirp(basepath, function(err) {
        if (err){
            callback(err);
        }else {
            fs.stat(path, function (err, stats) {
                if (err) {
                    callback(null, path);
                } else {
                    if (stats.isDirectory()) {
                        if (path.substr(path.length-1,1) != "/") {
                            path = path + "/";
                        }
                        path = path + lang + ".i18n.json";
                        callback(null, path);
                    } else {
                        callback(null, path);
                    }
                }
            });
        }
    });
}

//#--------------------------------------------------
//# saves tranaltion data to file.
//# @params
//#   path   - path under the file should be storedd
//#   data   - data buffer to save
//#   lang   - language code
//#   callback(err, path) - return error or path under the file was finally saved
saveTranslationToFile = function(path, data, lang, callback){
    convertToPath(path, lang , function(err, path){
        if (err){
            callback(err);
        }else{
            fs.writeFile(path, data, function(err){
                if (err){
                    callback(err, path);
                } else {
                    callback(null, path);
                }
            });
        }
    });
};

//#--------------------------------------------------
//# read translation file to buffer
//# @params
//#   path   - path under the file is stored
//#   lang   - language code
//#   callback(err, path) - return error or path under the file was finally saved
readTranslationFile = function(path, lang, callback){
    convertToPath(path, lang , function(err, path) {
        if (err){
            callback(err);
        }else {
            fs.readFile(path, 'utf8', function (err, data) {
                if (err) {
                    callback(err, path);
                } else {
                    callback(null, path, data);
                }
            });
        }
    });

};


//#--------------------------------------------------
//# get the file from lingohub
//# @params
//#   project   - name of the project
//#   lang      - lang code like es, en or pt-BR
//#   saveTo [optional] - path where the data should be saved, if the parameter is not available we won't save
//#   callback(err, data) - return error or buffer
getTranslationFile = function(project, lang, saveTo, options, callback) {

    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        if (err) {
            return callback(err);
        } else {

            args = {
                path: {
                    lang: lang,
                    account: authObj.account,
                    project: project
                },
                parameters: {
                    auth_token: authObj.token
                }
            };
            client.get("https://api.lingohub.com/v1/${account}/projects/${project}/resources/${lang}.i18n.json", args, function(data, response) {
                if (response.statusCode !== 200) {
                    return callback({
                        code: response.statusCode,
                        message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
                    });
                } else {
                    saveTranslationToFile(saveTo, data, lang, function(err, path){
                        callback(err, path);
                    });

                }
            });
        }
    });

};


//#--------------------------------------------------
//# pull all transalations for a project and save it to localdirectory.
//# @params
//#   project   - name of the project
//#   saveTo [optional] - path where the data should be saved, if the parameter is not available it will save the code to local i18n directory
//#   callback(err, data) - return error or buffer
pullAllTransaltions = function(project, saveTo, options, callback) {

    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        if (err) {
            return callback(err);
        } else {

            getProjectLocales(project, options, function(err, locales){
               if (err){
                   callback(err);
               } else{
                    var pulledLangs = [];

                    function iterator (lang, callback){
                        getTranslationFile(project, lang, saveTo, options,function(err, path){
                            if (!err) {
                                err="OK";
                            }
                            pulledLangs.push({lang:lang, path:path, error:err});
                            callback();
                        })
                    }

                    async.each(locales, iterator, function(err){
                        if (err){
                            callback(err);
                        }else{
                            callback(null, pulledLangs);
                        }
                    });
               }
            });
        }
    });

};



//#--------------------------------------------------
//# upload an i18n file from a path which is a file containing i18n text in lang
//# @params
//#   project - project name
//#   path    - path where the data file should be read from
//#   lang    - language code
//#   callback(err) - return error on problems enountered
uploadSrcFile = function(project, lang, srcPath,  options,  callback) {
    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        if (err) {
            return callback(err);
        } else {
            readTranslationFile(srcPath, lang, function(err, path,  data){
                if (err){
                    callback(err,path);
                }else{
                    formData = {
                        iso2_slug: lang,
                        path: "",
                        file: {
                            value: data,
                            options:{
                                filename: lang+'.i18n.json',
                                contentType: 'application/json'
                            }
                        }
                    };

                    request.post({url:'https://api.lingohub.com/v1/'+ authObj.account +'/projects/'+ project +'/resources.json?auth_token='+authObj.token, formData: formData}, function optionalCallback(err, httpResponse, body) {
                        if (err) {
                            callback(err, path);
                        }else{
                            callback(null, path);
                        }

                    });
                }
            });

        }
    });
};

//#--------------------------------------------------
//# pull all transalations for a project and save it to localdirectory.
//# @params
//#   project   - name of the project
//#   saveTo [optional] - path where the data should be saved, if the parameter is not available it will save the code to local i18n directory
//#   callback(err, data) - return error or buffer
pushAllFiles = function(project,  srcPath, options, callback) {

    if (_.isFunction(options)) {
        callback = options;
        options = {};
    }

    getLoginData(options, function(err, authObj) {
        if (err) {
            return callback(err);
        } else {

            getProjectLocales(project, options, function(err, locales){
                if (err){
                    callback(err);
                } else{
                    var pushedLangs = [];

                    function iterator (lang, callback){
                        uploadSrcFile(project, lang, srcPath, options,function(err, path){
                            if (!err) {
                                err="OK";
                            }
                            pushedLangs.push({lang:lang, path:path, error:err});
                            callback();

                        })
                    }

                    async.each(locales, iterator, function(err){
                        if (err){
                            callback(err);
                        }else{
                            callback(null, pushedLangs);
                        }
                    });
                }
            });
        }
    });

};





//#--------------------------------------------------
exports.login = login;
exports.logout = logout;
exports.getLoginData = getLoginData;
exports.projects = projects;
exports.getProject = getProject;
exports.getProjectLocales = getProjectLocales;
exports.getTranslationFile = getTranslationFile;
exports.uploadSrcFile = uploadSrcFile;
exports.saveTranslationToFile = saveTranslationToFile;
exports.pullAllTransaltions = pullAllTransaltions;
exports.pushAllFiles = pushAllFiles;
exports.convertToPath = convertToPath;
exports.auth_token_path = auth_token_path;
