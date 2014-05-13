window.Compiler = Compiler = {}

cache = {} # ID,parameter : exprString


Compiler.getExprString = (fn, parameter) ->
  key = C.id(fn) + "," + parameter
  return cache[key] if cache[key]?
  result = fn.getExprString(parameter)
  cache[key] = result
  return result

Compiler.setDirty = ->
  cache = {}
