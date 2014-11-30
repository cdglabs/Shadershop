


require("./util/util")
require("./config")
require("./model/C")
require("./Actions")
require("./Compiler")
require("./view/R")
require("./keyCommands")






storageName = config.storageName

isReloading = false
reloadPage = ->
  isReloading = true
  location.reload()

window.reset = ->
  delete window.localStorage[storageName]
  reloadPage()

if json = window.localStorage[storageName]
  json = JSON.parse(json)
  window.appRoot = C.reconstruct(json)
else
  window.appRoot = new C.AppRoot()

saveState = ->
  return if isReloading # so we don't overwrite while reloading
  json = C.deconstruct(appRoot)
  json = JSON.stringify(json)
  window.localStorage[storageName] = json


window.save = ->
  window.localStorage[storageName]

window.restore = (jsonString) ->
  if !_.isString(jsonString)
    jsonString = JSON.stringify(jsonString)
  window.localStorage[storageName] = jsonString
  reloadPage()



require("./UI")



# =============================================================================
# Animate Loop
# =============================================================================

debouncedSaveState = _.debounce(saveState, 400)

willRefreshNextFrame = false
refresh = ->
  return if willRefreshNextFrame
  willRefreshNextFrame = true
  requestAnimationFrame ->
    refreshView()
    # saveState()
    debouncedSaveState()
    willRefreshNextFrame = false

refreshView = ->
  appRootEl = document.querySelector("#AppRoot")
  React.renderComponent(R.AppRootView({appRoot}), appRootEl)



refreshEventNames = [
  "mousedown"
  "mousemove"
  "mouseup"
  "keydown"
  "scroll"
  "change"
  "wheel"
  "mousewheel"
]

for eventName in refreshEventNames
  window.addEventListener(eventName, refresh)

refresh()


# =============================================================================
# Auto-reload stylesheet
# =============================================================================

# Firefox crashes when the stylesheet reloads.
if location.protocol == "file:" and navigator.userAgent.indexOf("Firefox") == -1 and location.href.indexOf("dev.html") != -1
  setInterval(->
    document.styleSheets[0].reload()
  , 1000)
