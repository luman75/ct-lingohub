#
# ct-import
#
# Author: dutka
#
#
#
commandLineArgs = require('command-line-args')
lingohub = require './lingohub'

cli = commandLineArgs([
  { name: 'file' }
  { name: 'verbose' }
  { name: 'depth' }
  { name: 'help' }
])

try
  params = cli.parse()
catch e
  console.log(cli.getUsage)


console.log(params)


#
#
#
#lingohub.login "linguahouse-sp-dot-z-o-dot-o-dot", "6bd5ae4c83772a95da71bfe2a76d93f0bf436f6f166a66d3cfff12d3a6400f4e", (err) ->
#
#  lingohub.getProjectLocales "lingua-site", (err, data) ->
#    if err
#      console.error(err)
#    console.log(data)
#
#    lingohub.getFile "lingua-site", "fr", (err, data) ->
#      if err
#        console.error(err)
#      console.log(data)
#
