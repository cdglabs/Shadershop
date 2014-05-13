window.Actions = Actions = {}

# =============================================================================
# Manipulating Fn hierarchy
# =============================================================================

findParentOf = (childFnTarget) ->
  recurse = (compoundFn) ->
    if _.contains(compoundFn.childFns, childFnTarget)
      return compoundFn

    for childFn in compoundFn.childFns
      if childFn.fn instanceof C.CompoundFn
        if recurse(childFn.fn)
          return childFn.fn

    return null
  recurse(UI.selectedFn)


Actions.addDefinedFn = ->
  fn = new C.DefinedFn()
  appRoot.fns.push(fn)
  Compiler.setDirty()
  Actions.selectFn(fn)

Actions.addChildFn = (fn) ->
  if UI.selectedChildFn
    if UI.selectedChildFn.fn instanceof C.CompoundFn and UI.isChildFnExpanded(UI.selectedChildFn)
      parent = UI.selectedChildFn.fn
    else
      parent = findParentOf(UI.selectedChildFn)

  parent ?= UI.selectedFn
  childFn = new C.ChildFn(fn)
  Actions.insertChildFn(parent, childFn)
  Actions.selectChildFn(childFn)

Actions.addCompoundFn = ->
  # TODO more advanced
  fn = new C.CompoundFn()
  Actions.addChildFn(fn)

Actions.removeChildFn = (parentCompoundFn, childFn) ->
  index = parentCompoundFn.childFns.indexOf(childFn)
  return if index == -1
  parentCompoundFn.childFns.splice(index, 1)
  Compiler.setDirty()

Actions.insertChildFn = (parentCompoundFn, childFn, index) ->
  index = parentCompoundFn.childFns.length if !index?
  parentCompoundFn.childFns.splice(index, 0, childFn)
  Compiler.setDirty()


# =============================================================================
# Manipulating Fn incidentals
# =============================================================================

Actions.setFnLabel = (fn, newValue) ->
  fn.label = newValue

Actions.setCompoundFnCombiner = (compoundFn, combiner) ->
  compoundFn.combiner = combiner
  Compiler.setDirty()

Actions.setVariableValueString = (variable, newValueString) ->
  variable.valueString = newValueString
  Compiler.setDirty()

Actions.toggleChildFnVisible = (childFn) ->
  Actions.setChildFnVisible(childFn, !childFn.visible)

Actions.setChildFnVisible = (childFn, newVisible) ->
  childFn.visible = newVisible
  Compiler.setDirty()


# =============================================================================
# Manipulating Plots
# =============================================================================

Actions.panPlot = (plot, domainOffset, rangeOffset) ->
  plot.domainCenter = numeric.add(plot.domainCenter, domainOffset)
  plot.rangeCenter  = numeric.add(plot.rangeCenter,  rangeOffset)

Actions.zoomPlot = (plot, domainCenter, rangeCenter, scaleFactor) ->
  # scaleFactor > 1 is zoom "out"
  domainOffset = numeric.sub(plot.domainCenter, domainCenter)
  rangeOffset  = numeric.sub(plot.rangeCenter,  rangeCenter)

  plot.domainCenter = numeric.add(domainCenter, numeric.mul(scaleFactor, domainOffset))
  plot.rangeCenter  = numeric.add(rangeCenter,  numeric.mul(scaleFactor, rangeOffset))

  plot.scale *= scaleFactor


# =============================================================================
# Changing UI state (selection, hover, expanded)
# =============================================================================

Actions.selectFn = (fn) ->
  return unless fn instanceof C.DefinedFn
  UI.selectedFn = fn
  UI.selectedChildFn = null

Actions.selectChildFn = (childFn) ->
  UI.selectedChildFn = childFn

Actions.hoverChildFn = (childFn) ->
  UI.hoveredChildFn = childFn

Actions.toggleChildFnExpanded = (childFn) ->
  expanded = UI.isChildFnExpanded(childFn)
  Actions.setChildFnExpanded(childFn, !expanded)

Actions.setChildFnExpanded = (childFn, expanded) ->
  id = C.id(childFn)
  UI.expandedChildFns[id] = expanded



