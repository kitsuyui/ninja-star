minimist = require 'minimist'
NinjaStar = require 'ninja-star'

main = ->
  args = minimist process.argv.slice(2)
  if args._.length == 0
    console.log "usage: ninjastar configfile"
  else
    configurefile = args._[0]
    main_ configurefile, args

main_ = (configurefile, args) ->
  s = new NinjaStar
  s.loadFromFile configurefile
  first = ->
    s.generateNinja second
  second = ->
    if args.build
      s.doNinja third
    else
      third()
  third = ->
    if args.autobuild
      s.autobuild()
  first()

if require.main == module
  main()
