###

The idea here is that we're creating intermediate representations of each fn,
currently consisting of exprString:String and dependencies:[DefinedFn]. The
intermediate representation is created by getExprStringAndDependencies.

We currently cache each intermediate representation, and throw away the entire
cache if any function changes.

Cacheing is important because:

We can determine both the exprString and dependencies in a single pass, but we
usually only need (care to think about) one of these at a time.

We need to refer to the dependencies very frequently in order to compute
allDependencies. We don't want to repeat the work of figuring out
dependencies.

We need the exprString of a Fn for every Fn that is recursively dependent on
it.


What invalidates the cache, that is, what makes a Fn's intermediate
representation dirty?



What else do we need to add to the intermediate representation?

Dependencies on uniforms for scrubbing optimization. If only one ChildFn is
selected, then it will use uniform variables as its translate/transform
vectors/matrices so as to not have to recompile as the control points are
dragged around.

Dependencies on textures for ImageFn's.


What are other uses for intermediate representation?

Human readable "compiler".


What else might want to use this cache strategy?

Variables already kind of use it. We cache the (numeric) value of the Variable
even though it is derived from the stringValue (though kind of not, since an
invalid stringValue results in the last working value). We dirty check that by
just comparing is stringValue is the same as the last time variable.getValue()
was called.

The matrices/vectors in ChildFn probably want to do their own cacheing. Right
now they have to put together their values by getting the value of each
variable, which seems (?) expensive just because there are so many variables.
Also the matrix inversion function needed for the "divide" in domainTransform
is expensive and ought to be cached.

###


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







