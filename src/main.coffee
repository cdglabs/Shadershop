



require("./config")
require("./util/util")
require("./model/C")
require("./Actions")
require("./Compiler")
require("./view/R")






storageName = config.storageName

window.reset = ->
  delete window.localStorage[storageName]
  location.reload()

if json = window.localStorage[storageName]
  json = JSON.parse(json)
  window.appRoot = C.reconstruct(json)
else
  window.appRoot = new C.AppRoot()

saveState = ->
  json = C.deconstruct(appRoot)
  json = JSON.stringify(json)
  window.localStorage[storageName] = json


window.save = ->
  window.localStorage[storageName]

window.restore = (jsonString) ->
  if !_.isString(jsonString)
    jsonString = JSON.stringify(jsonString)
  window.localStorage[storageName] = jsonString
  location.reload()



require("./UI")



# =============================================================================
# Animate Loop
# =============================================================================

debouncedSaveState = _.debounce(saveState, 400)

dirty = true

animateLoop = ->
  requestAnimationFrame(animateLoop)
  if dirty
    refreshView()
    debouncedSaveState()
    dirty = false

setDirty = ->
  dirty = true

refreshView = ->
  appRootEl = document.querySelector("#AppRoot")
  React.renderComponent(R.AppRootView({appRoot}), appRootEl)

dirtyEventNames = [
  "mousedown"
  "mousemove"
  "mouseup"
  "keydown"
  "scroll"
  "change"
  "wheel"
  "mousewheel"
]

for eventName in dirtyEventNames
  window.addEventListener(eventName, setDirty)

animateLoop()


# =============================================================================
# Auto-reload stylesheet
# =============================================================================

# Firefox crashes when the stylesheet reloads.
if location.protocol == "file:" and navigator.userAgent.indexOf("Firefox") == -1
  setInterval(->
    document.styleSheets[0].reload()
  , 1000)
