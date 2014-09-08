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

ensureSelectedChildFnsVisible = ->
  expandedChildFns = getExpandedChildFns()
  UI.selectedChildFns = _.intersection(UI.selectedChildFns, expandedChildFns)


Actions.addDefinedFn = ->
  fn = new C.DefinedFn()
  appRoot.fns.push(fn)
  Compiler.setDirty()
  Actions.selectFn(fn)

Actions.addChildFn = (fn) ->
  if UI.selectedChildFns.length == 1
    possibleParent = UI.selectedChildFns[0].fn
    takesChildren = (possibleParent instanceof C.CompoundFn and UI.isChildFnExpanded(UI.selectedChildFns[0]))
    if takesChildren
      parent = possibleParent
      index = parent.childFns.length
    else
      {parent, index} = findParentIndexOf(UI.selectedChildFns[0])
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

Actions.addCompoundFn = (combiner="sum") ->
  compoundFn = new C.CompoundFn()
  compoundFn.combiner = combiner
  compoundFnContainer = new C.ChildFn(compoundFn)

  # Figure out where to add it
  childFnInfos = []
  for childFn in UI.selectedChildFns
    {parent, index} = findParentIndexOf(childFn)
    childFnInfos.push {parent, index, childFn}

  if childFnInfos.length > 0
    commonParent = childFnInfos[0].parent
    if _.all(childFnInfos, (childFnInfo) -> childFnInfo.parent == commonParent)
      # UI.selectedChildFns meets all criteria to be wrapped
      childFnInfos = _.sortBy(childFnInfos, "index")

      # Remove them from current location and into compoundFn
      for childFnInfo in childFnInfos
        Actions.removeChildFn(commonParent, childFnInfo.childFn)
        compoundFn.childFns.push(childFnInfo.childFn)

      # Insert compoundFnContainer
      index = childFnInfos[0].index
      commonParent.childFns.splice(index, 0, compoundFnContainer)

      Actions.selectChildFn(compoundFnContainer)
      return

  # UI.selectedChildFns did not meet the criteria, wrap the compoundFn around
  # everything.

  compoundFn.childFns = UI.selectedFn.childFns
  UI.selectedFn.childFns = [compoundFnContainer]
  Actions.selectChildFn(compoundFnContainer)
  Compiler.setDirty()

Actions.removeChildFn = (parentCompoundFn, childFn) ->
  index = parentCompoundFn.childFns.indexOf(childFn)
  return if index == -1
  parentCompoundFn.childFns.splice(index, 1)
  ensureSelectedChildFnsVisible()
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
  ensureSelectedChildFnsVisible()
  Compiler.setDirty()

Actions.setBasisVector = (childFn, space, coord, valueStrings) ->
  childFn.setBasisVector(space, coord, valueStrings)
  Compiler.setDirty()


# =============================================================================
# Manipulating Plots
# =============================================================================

Actions.panPlot = (plot, from, to) ->
  offset = numeric.sub(from, to)
  plot.center = numeric.add(plot.center, offset)

Actions.zoomPlot = (plot, zoomCenter, scaleFactor) ->
  # scaleFactor > 1 is zoom "out"

  offset = numeric.sub(plot.center, zoomCenter)
  plot.center = numeric.add(
    zoomCenter
    numeric.mul(offset, scaleFactor)
  )
  plot.pixelSize *= scaleFactor


# HACK: This duplicates information but I'll do it until I figure out a proper
# data model for PlotLayout, Plot, etc.

Actions.panPlotLayout = (plotLayout, from, to) ->
  for plot in plotLayout.plots
    Actions.panPlot(plot, from, to)

Actions.zoomPlotLayout = (plotLayout, zoomCenter, scaleFactor) ->
  for plot in plotLayout.plots
    Actions.zoomPlot(plot, zoomCenter, scaleFactor)

Actions.setPlotLayoutFocus = (plotLayout, focus) ->
  for plot in plotLayout.plots
    plot.focus = focus

# =============================================================================
# Changing UI state (selection, hover, expanded)
# =============================================================================

Actions.selectFn = (fn) ->
  return unless fn instanceof C.DefinedFn
  UI.selectedFn = fn
  UI.selectedChildFns = []
  Compiler.setDirty()

Actions.selectChildFn = (childFn) ->
  if childFn == null
    UI.selectedChildFns = []
  else
    UI.selectedChildFns = [childFn]
  ensureSelectedChildFnsVisible()
  Compiler.setDirty()

Actions.toggleSelectChildFn = (childFn) ->
  if _.contains(UI.selectedChildFns, childFn)
    UI.selectedChildFns = _.without(UI.selectedChildFns, childFn)
  else
    UI.selectedChildFns.push(childFn)
  ensureSelectedChildFnsVisible()
  Compiler.setDirty()

Actions.hoverChildFn = (childFn) ->
  UI.hoveredChildFn = childFn

Actions.toggleChildFnExpanded = (childFn) ->
  expanded = UI.isChildFnExpanded(childFn)
  Actions.setChildFnExpanded(childFn, !expanded)

Actions.setChildFnExpanded = (childFn, expanded) ->
  id = C.id(childFn)
  UI.expandedChildFns[id] = expanded
  ensureSelectedChildFnsVisible()



