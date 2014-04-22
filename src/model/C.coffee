window.C = C = {}


# =============================================================================
# Include all the model code
# =============================================================================

require("./model")


# =============================================================================
# Annotate each model class to have __className
# =============================================================================

for own className, constructor of C
  constructor.prototype.__className = className


# =============================================================================
# ID Management
# =============================================================================

C._idCounter = 0
C._assignId = (obj) ->
  @_idCounter++
  id = "id" + @_idCounter + Date.now() + Math.floor(1e9 * Math.random())
  obj.__id = id

C.id = (obj) ->
  obj.__id ? C._assignId(obj)


# =============================================================================
# Serialization
# =============================================================================

C.deconstruct = (object) ->
  objects = {} # id : object
  serialize = (object, force=false) =>
    if !force and object?.__className
      id = C.id(object)
      if !objects[id]
        objects[id] = serialize(object, true)
      return {__ref: id}

    if _.isArray(object)
      result = []
      for entry in object
        result.push(serialize(entry))
      return result

    if _.isObject(object)
      result = {}
      for own key, value of object
        result[key] = serialize(value)
      if object.__className
        result.__className = object.__className
      return result

    return object ? null

  root = serialize(object)

  return {objects, root}

C.reconstruct = ({objects, root}) ->
  # Construct all the objects

  constructedObjects = {} # id : object

  constructObject = (object) =>
    className = object.__className
    classConstructor = C[className]
    constructedObject = new classConstructor()
    for own key, value of object
      continue if key == "__className"
      constructedObject[key] = value
    return constructedObject

  for own id, object of objects
    constructedObjects[id] = constructObject(object)

  # Replace all {__ref} with the actual object

  derefObject = (object) =>
    return unless _.isObject(object)
    for own key, value of object
      if id = value?.__ref
        object[key] = constructedObjects[id]
      else
        derefObject(value)

  for own id, object of constructedObjects
    derefObject(object)

  return constructedObjects[root.__ref]
