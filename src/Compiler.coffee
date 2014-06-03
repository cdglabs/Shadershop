window.Compiler = Compiler = {}

# Constants
vecType = util.glslVectorType(config.dimensions)
zeroVectorString = util.glslString(util.constructVector(config.dimensions, 0))
identityMatrixString = util.glslString(numeric.identity(config.dimensions))


cache = {} # ID : {exprString, dependencies}

Compiler.setDirty = ->
  cache = {}

getExprStringAndDependencies = (fn) ->
  id = C.id(fn)
  return cache[id] if cache[id]?

  dependencies = []
  recurse = (fn, parameter, firstCall=false) ->
    if fn instanceof C.BuiltInFn
      if fn.fnName == "identity"
        return parameter
      return "#{fn.fnName}(#{parameter})"

    if fn instanceof C.DefinedFn and !firstCall
      dependencies.push(fn)
      return "#{C.id(fn)}(#{parameter})"

    if fn instanceof C.CompoundFn
      visibleChildFns = _.filter fn.childFns, (childFn) -> childFn.visible

      if fn.combiner == "last"
        if visibleChildFns.length > 0
          return recurse(_.last(visibleChildFns), parameter)
        else
          return util.glslString(util.constructVector(config.dimensions, 0))

      if fn.combiner == "composition"
        exprString = parameter
        for childFn in visibleChildFns
          exprString = recurse(childFn, exprString)
        return exprString

      childExprStrings = visibleChildFns.map (childFn) =>
        recurse(childFn, parameter)

      if fn.combiner == "sum"
        if childExprStrings.length == 0
          return util.glslString(util.constructVector(config.dimensions, 0))
        else
          return "(" + childExprStrings.join(" + ") + ")"

      if fn.combiner == "product"
        if childExprStrings.length == 0
          return util.glslString(util.constructVector(config.dimensions, 1))
        else
          return "(" + childExprStrings.join(" * ") + ")"

    if fn instanceof C.ChildFn
      domainTranslate    = util.glslString(fn.getDomainTranslate())
      domainTransformInv = util.glslString(util.safeInv(fn.getDomainTransform()))
      rangeTranslate     = util.glslString(fn.getRangeTranslate())
      rangeTransform     = util.glslString(fn.getRangeTransform())

      exprString = parameter

      if domainTranslate != zeroVectorString
        exprString = "(#{exprString} - #{domainTranslate})"

      if domainTransformInv != identityMatrixString
        exprString = "(#{domainTransformInv} * #{exprString})"

      exprString = recurse(fn.fn, exprString)

      if rangeTransform != identityMatrixString
        exprString = "(#{rangeTransform} * #{exprString})"

      if rangeTranslate != zeroVectorString
        exprString = "(#{exprString} + #{rangeTranslate})"

      return exprString

  exprString = recurse(fn, "inputVal", true)

  result = {exprString, dependencies}

  cache[id] = result
  return result


getDependencies = (fn) ->
  return getExprStringAndDependencies(fn).dependencies

getAllDependencies = (fn) ->
  # Returns all dependencies in order e.g. [A, B] then A does not depend on B,
  # so the dependencies can be listed in order in code without a problem.

  allDependencies = []
  recurse = (fn) ->
    dependencies = getDependencies(fn)
    allDependencies = allDependencies.concat(dependencies)
    for dependency in dependencies
      recurse(dependency)
  recurse(fn)

  allDependencies.reverse()
  allDependencies = _.unique(allDependencies)

  return allDependencies

getGlslFnString = (fn, name) ->
  name ?= C.id(fn)
  {exprString} = getExprStringAndDependencies(fn)
  return "#{vecType} #{name}(#{vecType} inputVal) {return #{exprString};}"


Compiler.getGlsl = (fn) ->
  {exprString} = getExprStringAndDependencies(fn)
  allDependencies = getAllDependencies(fn)

  fnStrings = (getGlslFnString(dependency) for dependency in allDependencies)

  fnStrings.push getGlslFnString(fn, "mainFn")

  return fnStrings.join("\n")







