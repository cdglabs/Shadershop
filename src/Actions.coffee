window.Actions = Actions = {}


# =============================================================================
# Manipulating Fn hierarchy
# =============================================================================

findParentIndexOf = (childFnTarget) ->
  recurse = (compoundFn) ->
    index = compoundFn.childFns.indexOf(childFnTarget)
    if index != -1
      return {
        parent: compoundFn
        index: index
      }

    for childFn in compoundFn.childFns
      if childFn.fn instanceof C.CompoundFn
        if found = recurse(childFn.fn)
          return found

    return null
  recurse(UI.selectedFn)

getExpandedChildFns = ->
  result = []
  recurse = (childFns) ->
    for childFn in childFns
      continue unless childFn.visible
      result.push(childFn)
      if UI.isChildFnExpanded(childFn) and childFn.fn instanceof C.CompoundFn
        recurse(childFn.fn.childFns)
  recurse(UI.selectedFn.childFns)
  return result

ensureSelectedChildFnVisible = ->
  if UI.selectedChildFn
    if !_.contains(getExpandedChildFns(), UI.selectedChildFn)
      UI.selectedChildFn = null


Actions.addDefinedFn = ->
  fn = new C.DefinedFn()
  appRoot.fns.push(fn)
  Compiler.setDirty()
  Actions.selectFn(fn)

Actions.addChildFn = (fn) ->
  if UI.selectedChildFn
    possibleParent = UI.selectedChildFn.fn
    takesChildren = (possibleParent instanceof C.CompoundFn and UI.isChildFnExpanded(UI.selectedChildFn))
    if takesChildren
      parent = possibleParent
      index = parent.childFns.length
    else
      {parent, index} = findParentIndexOf(UI.selectedChildFn)
      index = index + 1 # insert it after the selectedChildFn

  else
    if UI.selectedFn.childFns.length == 1
      onlyChild = UI.selectedFn.childFns[0]
      possibleParent = onlyChild.fn
      takesChildren = (possibleParent instanceof C.CompoundFn and UI.isChildFnExpanded(onlyChild))
      if takesChildren
        parent = possibleParent
        index = parent.childFns.length

  if !parent?
    parent = UI.selectedFn
    index = parent.childFns.length

  childFn = new C.ChildFn(fn)
  Actions.insertChildFn(parent, childFn, index)
  Actions.selectChildFn(childFn)
  return {childFn, parent, index}

Actions.addCompoundFn = ->
  fn = new C.CompoundFn()
  fn.childFns = UI.selectedFn.childFns
  childFn = new C.ChildFn(fn)
  UI.selectedFn.childFns = [childFn]
  Compiler.setDirty()

Actions.removeChildFn = (parentCompoundFn, childFn) ->
  index = parentCompoundFn.childFns.indexOf(childFn)
  return if index == -1
  parentCompoundFn.childFns.splice(index, 1)
  ensureSelectedChildFnVisible()
  Compiler.setDirty()

Actions.insertChildFn = (parentCompoundFn, childFn, index) ->
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
  ensureSelectedChildFnVisible()
  Compiler.setDirty()

Actions.setBasisVector = (childFn, space, coord, valueStrings) ->
  childFn.setBasisVector(space, coord, valueStrings)
  Compiler.setDirty()


# =============================================================================
# Manipulating Plots
# =============================================================================

Actions.panPlot = (plot, from, to) ->
  domainOffset = util.vector.sub(from.domain, to.domain)
  rangeOffset  = util.vector.sub(from.range,  to.range)

  newDomainCenter = util.vector.add(plot.domainCenter, domainOffset)
  newRangeCenter  = util.vector.add(plot.rangeCenter,  rangeOffset)

  plot.domainCenter = util.vector.merge(plot.domainCenter, newDomainCenter)
  plot.rangeCenter  = util.vector.merge(plot.rangeCenter,  newRangeCenter)

Actions.zoomPlot = (plot, zoomCenter, scaleFactor) ->
  # scaleFactor > 1 is zoom "out"

  domainOffset = util.vector.sub(plot.domainCenter, zoomCenter.domain)
  rangeOffset  = util.vector.sub(plot.rangeCenter,  zoomCenter.range)

  newDomainCenter = util.vector.add(zoomCenter.domain, util.vector.mul(scaleFactor, domainOffset))
  newRangeCenter  = util.vector.add(zoomCenter.range,  util.vector.mul(scaleFactor, rangeOffset))

  plot.domainCenter = util.vector.merge(plot.domainCenter, newDomainCenter)
  plot.rangeCenter  = util.vector.merge(plot.rangeCenter,  newRangeCenter)

  plot.pixelSize *= scaleFactor


# HACK: This duplicates information but I'll do it until I figure out a proper
# data model for PlotLayout, Plot, etc.

Actions.panPlotLayout = (plotLayout, from, to) ->
  for plot in plotLayout.plots
    Actions.panPlot(plot, from, to)

Actions.zoomPlotLayout = (plotLayout, zoomCenter, scaleFactor) ->
  for plot in plotLayout.plots
    Actions.zoomPlot(plot, zoomCenter, scaleFactor)

# =============================================================================
# Changing UI state (selection, hover, expanded)
# =============================================================================

Actions.selectFn = (fn) ->
  return unless fn instanceof C.DefinedFn
  UI.selectedFn = fn
  UI.selectedChildFn = null

Actions.selectChildFn = (childFn) ->
  UI.selectedChildFn = childFn
  ensureSelectedChildFnVisible()

Actions.hoverChildFn = (childFn) ->
  UI.hoveredChildFn = childFn

Actions.toggleChildFnExpanded = (childFn) ->
  expanded = UI.isChildFnExpanded(childFn)
  Actions.setChildFnExpanded(childFn, !expanded)

Actions.setChildFnExpanded = (childFn, expanded) ->
  id = C.id(childFn)
  UI.expandedChildFns[id] = expanded
  ensureSelectedChildFnVisible()



