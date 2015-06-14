#!/usr/bin/env coffee
async = require 'async'
child_process = require 'child_process'
fs = require 'fs'
fsmonitor = require 'fsmonitor'
glob = require 'glob'
minimatch = require 'minimatch'
ninjaBulidGen = require 'ninja-build-gen'
path = require 'path'
require 'coffee-script/register'


replacePath = (filepath, replaceExt, dest) ->
  ext = path.extname filepath
  if replaceExt
    base = path.basename(filepath, ext) + replaceExt
  else
    base = path.basename filepath
  path.join dest, base


class NinjaStar
  constructor: ->
    @ninja = null
    @memoryTargets = []
    @rules = {}
    @buildLines = []
    @watchDir = '.'
    @loadfile = null

  loadFromFile: (filepath) ->
    filepath2 = path.resolve filepath
    o = require filepath2
    @loadfile = filepath2
    @applyRules o.rules
    @applyBuildLines o.buildlines
    @watchDir = o.watchDir
    delete require.cache[filepath2]

  applyRules: (rules) ->
    @rules = {}
    for own k, v of rules
      @rules[k] = v

  applyBuildLines: (bls) ->
    @buildLines = [].concat(bls)

  doNinja: (callback) ->
    child = child_process.spawn 'ninja'
    child.stderr.on 'data', (chunk) ->
      process.stderr.write chunk
    child.stdout.on 'data', (chunk) ->
      process.stdout.write chunk
    child.on 'close', (code) ->
      callback()

  autobuild: () ->
    doNinja2 = () =>
      @doNinja ->
        null
    fs.watch @loadfile, (event, filename) =>
      @loadFromFile @loadfile
      @generateNinja doNinja2

    fsmonitor.watch @watchDir, null, (changes) =>
      @generateNinja doNinja2

  mem: (filepath) ->
    if filepath not in @memoryTargets
      @memoryTargets.push filepath

  mem_matcher: (pattern) =>
    return (f for f in @memoryTargets when minimatch(f, pattern))

  register: (filepaths, using, dest) ->
    @ninja.edge(dest).from(filepaths).using(using)
    for filepath in filepaths
      @mem filepath
    @mem dest

  registerAggregate: (filepaths, using, dest) ->
    @register filepaths, using, dest

  registerSingle: (filepath, using, dest) ->
    rule = @rules[using]
    unless rule
      console.log 'cannot load rule: ' + using
      return
    newPath = replacePath filepath, rule.to_ext, dest
    @register [filepath], using, newPath

  findTargetsSingle: (pattern, callback) ->
    glob pattern, {}, (err, globhitfiles) =>
      targetFiles = globhitfiles.concat @mem_matcher(pattern)
      callback err, targetFiles

  findTargets: (patterns, callback) ->
    if typeof patterns is 'string'
      @findTargetsSingle patterns, callback
    else
      d = []
      x = patterns.map (pattern) => (cb) =>
        @findTargetsSingle pattern, (err, targetFiles) =>
          for f in targetFiles
            d.push(f)
          cb()
      async.series x, () ->
        callback null, d

  single: (command, pattern, dest, callback) =>
    @findTargets pattern, (err, files) =>
      @registerSingle f, command, dest for f in files
      callback()

  aggregate: (command, pattern, dest, callback) =>
    @findTargets pattern, (err, files) =>
      @registerAggregate files, command, dest
      callback()

  linePattern: (name) ->
    p =
      single: @single
      aggregate: @aggregate
    return p[name]

  generateNinja: (callback) =>
    @ninja = ninjaBulidGen null, 'build'
    @memoryTargets = []

    for own name, conf of @rules
      rule = @ninja.rule name
      rule.run conf.command
      if conf.description
        rule.description conf.description

    mapping = @buildLines.map (buildline) => (callback) =>
      ruleName = buildline[0]
      type = @rules[ruleName].type || 'single'
      fn = @linePattern type
      args = buildline.concat [callback]
      fn.apply null, args

    async.series mapping, (err, results) =>
      @ninja.save 'build.ninja', ->
        callback()

module.exports = NinjaStar
