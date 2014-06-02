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


Compiler.getAllDefinedFnExprStrings = ->
  result = {}
  for definedFn in appRoot.fns
    if definedFn.childFns.length > 0
      lastChildFn = _.last(definedFn.childFns)
      exprString = Compiler.getExprString(lastChildFn, "inputVal")
    else
      exprString = util.glslString(util.constructVector(config.dimensions, 0))
    result[C.id(definedFn)] = exprString
  return result
