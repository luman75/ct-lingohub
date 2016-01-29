# ct-lingohub i18n to lingohub

This is command line interface for accessing and managing i18n files in LingoHub. 
It's crafted for special requirements we had and it shouldn't be treated as a generic universal solution. 

# Installation 
```
$ npm install -g ct-lingohub
```

After that you should have on your path avai

# Getting Started
The typical scenio looks like this:

#### Step 1 ```Login``` (only once)
Before we start we need to save our login credentials. 

```
$ ct-lingohub login -t "XXXXXXX3cfff12d3a6400f4eXXXXX" -a "YOURACCOUNTNAME"
Login successfuly. Your credentials are saved in ~/.ct-import.auth
```

Operation login saves  creditentials in file  ```~/.ct-import.auth```.

#### Step 2 ```Push``` the current status of the project to remote repo:
In the push command we need to provide name of the project. In the example below we are working with project ```linguatest```.

The push operation gets all i18n files for predefined languages in Lingohub system and upload the data.  

```
$ ct-lingohub push -p linguatest
Successfully pushed all local files to lingohub linguatest:

{ lang: 'pl', path: 'i18n/pl.i18n.json', error: 'OK' }
{ lang: 'ja', path: 'i18n/ja.i18n.json', error: 'OK' }
{ lang: 'en', path: 'i18n/en.i18n.json', error: 'OK' }
```


#### Step 3 ```Pull``` current translations from lingohub
The next process in the flow is to download the current status of the translation.  Command pull gets data from Lingohub and
 override existing file in default directory

```
$ ct-lingohub pull -p linguatest
Successfully pulled translations for project linguatest:

{ lang: 'en', path: 'i18n/en.i18n.json', error: 'OK' }
{ lang: 'pl', path: 'i18n/pl.i18n.json', error: 'OK' }
{ lang: 'ja', path: 'i18n/ja.i18n.json', error: 'OK' }
```


# Available commands

There are avilable the following commands: 
 
 * login
 * logout
 * projects
 * project-info
 * locals
 * download
 * upload
 * pull
 * push


## login
```
$ ct-lingohub login --help
usage: ct-lingohub login [-h] -t TOKEN -a ACCOUNT

Login to lingohub and stores login token in ~/.ct-import.auth file

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN

```

## logout

```
$ ./ct-lingohub logout --help
usage: ct-lingohub logout [-h]

Logout from lingohub. It removes login token from ~/.ct-import.auth file

Optional arguments:
  -h, --help  Show this help message and exit.

```

## projects

```
$ ./ct-lingohub projects --help
usage: ct-lingohub projects [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n]

List all projects registered in the system

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
```

## project-info
```
$ ./ct-lingohub project-info --help
usage: ct-lingohub project-info [-h] [-t TOKEN] [-a ACCOUNT] [-j] -p PROJECT
                                [-n]
                                

Get detailed inforamtion about a particular project

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -p PROJECT, --project PROJECT
                        project name to displayed information about
  -n, --no-header       Do not print any headers for the results - just data
```
## locals

```
$ ./ct-lingohub locals --help      
usage: ct-lingohub locals [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n] -p PROJECT

List all destination languages defined in a particular project

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
  -p PROJECT, --project PROJECT
                        project name to displayed information about
```

## download
```
$ ./ct-lingohub download --help
usage: ct-lingohub download [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n] -p PROJECT
                            -l LANG [-f PATH]
                            

get a translation file for a project

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
  -p PROJECT, --project PROJECT
                        project name to displayed information about
  -l LANG, --lang LANG  language code for the expected translation i.e.:es or 
                        ar-AE
  -f PATH, --path PATH  save translation file under path. If not provided 
                        default it will save to ./i18n/#{lang}.i18n.json                       
```


## upload

```
$ ./ct-lingohub upload --help  
usage: ct-lingohub upload [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n] -p PROJECT -l
                          LANG [-f PATH]
                          

upload a source file to lingohub

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
  -p PROJECT, --project PROJECT
                        project name to displayed information about
  -l LANG, --lang LANG  language code for the expected translation i.e.:es or 
                        ar-AE
  -f PATH, --path PATH  save translation file under to path. If not provided 
                        default it will save to ./i18n/#{lang}.i18n.json
```


## pull

```
$ ./ct-lingohub pull --help  
usage: ct-lingohub pull [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n] -p PROJECT
                        [-f PATH]
                        

pull entire project translation status

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
  -p PROJECT, --project PROJECT
                        project name to displayed information about
  -f PATH, --path PATH  save translation file under to path. If not provided 
                        default it will save to ./i18n/#{lang}.i18n.json
```

## push
```
$ ./ct-lingohub push --help
usage: ct-lingohub push [-h] [-t TOKEN] [-a ACCOUNT] [-j] [-n] -p PROJECT
                        [-f PATH]
                        

push all translations files into LinguHubs system.

Optional arguments:
  -h, --help            Show this help message and exit.
  -t TOKEN, --token TOKEN
                        token to be used for accessing Lingogub API
  -a ACCOUNT, --account ACCOUNT
                        account name to be used together with TOKEN
  -j, --json            Print results in json format only
  -n, --no-header       Do not print any headers for the results - just data
  -p PROJECT, --project PROJECT
                        project name to displayed information about
  -f PATH, --path PATH  save translation file under to path. If not provided 
                        default it will save to ./i18n/#{lang}.i18n.json
```