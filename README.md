# NinjaStar

This repository is currently work in progress.

# Installation

```ShellSession
$ npm install -g ninja-star
```

# Usage

## Just generate `build.ninja'

```ShellSession
$ ninjastar configure.coffee
```

## With building (run ```ninja```) 

```ShellSession
$ ninjastar configure.coffee --build
```

## Automation

```ShellSession
$ ninjastar configure.coffee --build --autobuild
```

# configure

```CoffeeScript
module.exports =
  buildlines: [
    ['coffee', 'src/coffee/*.coffee', '$builddir/js']
  ]
  rules:

    coffee:
      to_ext: '.js'
      command: 'coffee -cs < $in > $out'
      description: "Compile CoffeeScript '$in' to '$out'."

  watchDir: 'src'
```

# More complicated configure

```CoffeeScript
process.env.PATH = process.env.PATH + ":./node_modules/.bin"

module.exports =
  buildlines: [
    ['coffee', 'src/coffee/*.coffee', '$builddir/js']
    ['stylus', 'src/stylus/*.+(stylus|styl)', '$builddir/css']
    ['jade', 'src/jade/*.jade', '$builddir/html']
    ['copy', 'src/js/*.js', '$builddir']
    ['copy', '$builddir/html/*.html', 'site/']
    [
      'uglifyjs', [
        'bower_components/jQuery/dist/jquery.js'
        'bower_components/moment/moment.js'
        '$builddir/js/*.js'
      ], 'site/js/all.js']
    [
      'uglifycss', [
        '$builddir/css/*.css'
      ], 'site/css/all.css']
  ]
  rules:
    copy:
      command: 'cp -p $in $out'
      description: "Copy '$in' to '$out'"

    coffee:
      to_ext: '.js'
      command: 'coffee -cs < $in > $out'
      description: "Compile CoffeeScript '$in' to '$out'."

    stylus:
      to_ext: '.css'
      command: 'stylus < $in > $out'
      description: "Compile Stylus '$in' to '$out'."

    jade:
      to_ext: '.html'
      command: 'jade < $in > $out'
      description: "Compile Jade '$in' to '$out'."

    yaml:
      to_ext: '.json'
      command: "yaml2json $in > $out"
      description: "Compile YAML '$in' to '$out'."

    catenate:
      type: 'aggregate'
      command: 'cat $in > $out'

    uglifyjs:
      type: 'aggregate'
      command: 'uglifyjs $in > $out'
      description: "Minify '$in' to '$out' ."

    uglifycss:
      type: 'aggregate'
      command: 'cat $in | minify > $out'
      description: "Minify '$in' to '$out' ."

  watchDir: 'src'
```
