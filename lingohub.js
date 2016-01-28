var fs = require('fs');
var Client = require('node-rest-client').Client;
var client = new Client();
var expandTilde = require('expand-tilde');
var _ = require('underscore');

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
    return getLoginData(options, function(err, authObj) {
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
                    return callback(null, data);
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
getProject = function(project, callback) {
    var args;
    if ((typeof auth_token === "undefined" || auth_token === null) || (typeof account === "undefined" || account === null)) {
        callback({
            message: "You need to login first"
        });
        return;
    }
    args = {
        path: {
            account: account,
            project: project
        },
        parameters: {
            auth_token: auth_token
        }
    };
    return client.get("https://api.lingohub.com/v1/${account}/projects/${project}.json", args, function(data, response) {
        if (response.statusCode !== 200) {
            return callback({
                code: response.statusCode,
                message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
            });
        } else {
            return callback(null, data);
        }
    });
};

//#--------------------------------------------------
//# function returns current list of project locales or error
//# @params
//#     project
//#     callback(err, locales) - returns errors or array of of locales
getProjectLocales = function(project, callback) {
    return getProject(project, function(err, data) {
        if (err) {
            return callback(err);
        } else {
            return callback(null, data.project_locales);
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
getFile = function(project, lang, saveTo, callback) {
    var args;
    if ((typeof auth_token === "undefined" || auth_token === null) || (typeof account === "undefined" || account === null)) {
        callback("You need to login first");
        return;
    }
    args = {
        path: {
            account: account,
            project: project,
            lang: lang
        },
        parameters: {
            auth_token: auth_token
        }
    };
    return client.get("https://api.lingohub.com/v1/${account}/projects/${project}/resources/${lang}.i18n.json", args, function(data, response) {
        if (response.statusCode !== 200) {
            return callback({
                code: response.statusCode,
                message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
            });
        } else {
            return callback(null, data);
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
uploadFile = function(project, path, lang, callback) {
    var args;
    if ((typeof auth_token === "undefined" || auth_token === null) || (typeof account === "undefined" || account === null)) {
        callback("You need to login first");
        return;
    }
    args = {
        path: {
            account: account,
            project: project,
            lang: lang
        },
        parameters: {
            auth_token: auth_token
        }
    };
    return client.get("https://api.lingohub.com/v1/${account}/projects/${project}/resources/${lang}.i18n.json", args, function(data, response) {
        if (response.statusCode !== 200) {
            return callback({
                code: response.statusCode,
                message: "Error. Status Code: " + response.statusCode + " " + response.statusMessage
            });
        } else {
            return callback(null, data);
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
exports.getFile = getFile;
exports.uploadFile = uploadFile;
exports.auth_token_path = auth_token_path;
