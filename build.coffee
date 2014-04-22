fs      = require("fs")
watcher = require("node-watch")

stitch  = require("stitch")
stylus  = require("stylus")




buildScripts = ->
  IN_DIR   = "./src"
  OUT_FILE = "compiled/app.js"

  build = ->
    # Stitch
    pkg = stitch.createPackage({paths: [IN_DIR]})
    pkg.compile (err, output) ->
      if err
        console.warn err
        return

      fs.writeFile OUT_FILE, output, (err) ->
        if err then throw err
        console.log "compiled: #{OUT_FILE}"

    # Stylus
    fs.readFile "./src/style/style.styl", "utf8", (err, data) ->
      stylus.render data, (err, css) ->
        fs.writeFile "compiled/app.css", css, (err) ->
          if err then throw err
          console.log "compiled: compiled/app.css"

  build()
  watcher(IN_DIR, build)


buildScripts()