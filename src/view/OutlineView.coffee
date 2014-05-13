R.create "OutlineView",
  propTypes:
    definedFn: C.DefinedFn

  render: ->
    R.div {className: "Outline"},
      R.OutlineChildrenView {
        compoundFn: @definedFn
      }

      R.div {className: "TextButton", onClick: @_onAddButtonClick}, "Add"

      if UI.selectedChildFn
        R.OutlineControlsView {fn: UI.selectedChildFn}

  _onAddButtonClick: ->
    Actions.addCompoundFn()


# =============================================================================

R.create "OutlineChildrenView",
  propTypes:
    compoundFn: C.CompoundFn

  render: ->
    R.div {className: "OutlineChildren"},
      for childFn in @compoundFn.childFns
        R.OutlineItemView {
          childFn: childFn
          key: C.id(childFn)
        }


# =============================================================================

R.create "OutlineItemView",
  propTypes:
    childFn: C.ChildFn

  render: ->
    if !@isDraggingCopy and @childFn == UI.dragging?.childFn
      return R.div {className: "Placeholder", style: {height: UI.dragging.placeholderHeight}}

    canHaveChildren = @childFn.fn instanceof C.CompoundFn
    expanded = UI.isChildFnExpanded(@childFn)
    selected = (@childFn == UI.selectedChildFn)
    hovered = (@childFn == UI.hoveredChildFn)

    itemClassName = R.cx {
      OutlineItem: true
      Invisible: !@childFn.visible
    }

    rowClassName = R.cx {
      OutlineRow: true
      Selected: selected
      Hovered: hovered
    }

    disclosureClassName = R.cx {
      DisclosureTriangle: true
      Expanded: expanded
    }

    R.div {className: itemClassName},
      R.div {className: rowClassName, onMouseDown: @_onRowMouseDown, onMouseEnter: @_onRowMouseEnter, onMouseLeave: @_onRowMouseLeave},
        R.div {className: "OutlineVisible", onClick: @_onVisibleClick},
          R.div {className: "icon-eye"}

        if canHaveChildren
          R.div {className: "OutlineDisclosure", onClick: @_onDisclosureClick},
            R.div {className: disclosureClassName}

        R.OutlineThumbnailView {childFn: @childFn}

        R.OutlineInternalsView {fn: @childFn.fn}

      if canHaveChildren and expanded
        R.OutlineChildrenView {
          compoundFn: @childFn.fn
        }

  _onDisclosureClick: ->
    Actions.toggleChildFnExpanded(@childFn)

  _onVisibleClick: ->
    Actions.toggleChildFnVisible(@childFn)

  _onRowMouseDown: (e) ->
    return unless e.target.classList.contains("OutlineRow")

    util.preventDefault(e)

    Actions.selectChildFn(@childFn)

    el = @getDOMNode()
    rect = el.getMarginRect()
    myWidth = rect.width
    myHeight = rect.height
    offset = {
      x: e.clientX - rect.left
      y: e.clientY - rect.top
    }

    UI.dragging = {
      cursor: "-webkit-grabbing"
    }

    childFn = @childFn
    parentCompoundFn = @lookup("compoundFn")

    util.onceDragConsummated e, =>
      UI.dragging = {
        cursor: "-webkit-grabbing"
        offset: offset
        placeholderHeight: myHeight
        childFn: childFn
        render: =>
          R.div {style: {width: myWidth, height: myHeight, overflow: "hidden", "background-color": "#fff"}},
            R.OutlineItemView {childFn, isDraggingCopy: true}
        onMove: =>
          draggingPosition = {
            x: UI.mousePosition.x - offset.x
            y: UI.mousePosition.y - offset.y
          }

          # Hide placeholder for purposes of this calculation
          placeholderEl = document.querySelector(".Placeholder")
          placeholderEl?.style.display = "none"

          # Keep track of the best dropping opportunity
          bestQuadrance = 40*40
          bestDrop = null
          checkFit = (droppedPosition, outlineChildrenEl, index) ->
            dx = draggingPosition.x - droppedPosition.x
            dy = draggingPosition.y - droppedPosition.y
            quadrance = dx*dx + dy*dy
            if quadrance < bestQuadrance
              bestQuadrance = quadrance
              bestDrop = {outlineChildrenEl, index}

          outlineChildrenEls = document.querySelectorAll(".Outline .OutlineChildren")
          for outlineChildrenEl in outlineChildrenEls
            # Check before each existing child
            outlineItemEls = _.filter(outlineChildrenEl.childNodes, (el) -> el.classList.contains("OutlineItem"))
            for outlineItemEl, index in outlineItemEls
              rect = outlineItemEl.getBoundingClientRect()
              droppedPosition = {
                x: rect.left
                y: rect.top
              }
              checkFit(droppedPosition, outlineChildrenEl, index)
            # Check after the last child
            rect = outlineChildrenEl.getBoundingClientRect()
            droppedPosition = {
              x: rect.left
              y: rect.bottom
            }
            checkFit(droppedPosition, outlineChildrenEl, index)

          # Reshow placeholder
          placeholderEl?.style.display = ""


          # Remove self
          if parentCompoundFn
            Actions.removeChildFn(parentCompoundFn, childFn)
            parentCompoundFn = null

          # Add self
          if bestDrop
            parentCompoundFn = bestDrop.outlineChildrenEl.dataFor.compoundFn
            Actions.insertChildFn(parentCompoundFn, childFn, bestDrop.index)

      }

  _onRowMouseEnter: ->
    Actions.hoverChildFn(@childFn)

  _onRowMouseLeave: ->
    Actions.hoverChildFn(null)


# =============================================================================

R.create "OutlineInternalsView",
  propTypes:
    fn: C.Fn

  render: ->
    R.div {className: "OutlineInternals"},
      if @fn instanceof C.BuiltInFn
        R.LabelView {fn: @fn}

      else if @fn instanceof C.DefinedFn
        R.LabelView {fn: @fn}

      else if @fn instanceof C.CompoundFn
        R.CombinerView {compoundFn: @fn}


# =============================================================================

R.create "OutlineThumbnailView",
  propTypes:
    childFn: C.ChildFn

  render: ->
    bounds = UI.selectedFn.bounds # HACK
    R.div {className: "OutlineThumbnail"},
      R.div {className: "PlotContainer"},
        R.GridView {bounds}

        R.ShaderCartesianView {
          bounds
          plots: [
            {
              exprString: @childFn.getExprString("x")
              color: config.color.main
            }
          ]
        }

# =============================================================================

R.create "LabelView",
  propTypes:
    fn: C.Fn

  render: ->
    R.TextFieldView {
      className: "OutlineLabel"
      value: @fn.label
      onInput: @_onInput
    }

  _onInput: (newValue) ->
    Actions.setFnLabel(@fn, newValue)


# =============================================================================

R.create "CombinerView",
  propTypes:
    compoundFn: C.CompoundFn

  render: ->
    R.select {value: @compoundFn.combiner, onChange: @_onChange},
      R.option {value: "sum"}, "Add"
      R.option {value: "product"}, "Multiply"
      R.option {value: "composition"}, "Compose"

  _onChange: (e) ->
    value = e.target.selectedOptions[0].value
    Actions.setCompoundFnCombiner(@compoundFn, value)










# =============================================================================

# TODO: Move this into Inspector

R.create "OutlineControlsView",
  propTypes:
    fn: C.ChildFn

  render: ->
    R.table {},
      R.tr {},
        @fn.domainTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}
        @fn.rangeTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}

      for coordIndex in [0...config.dimensions]
        R.tr {key: coordIndex},
          for rowIndex in [0...config.dimensions]
            variable = @fn.domainTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}
          for rowIndex in [0...config.dimensions]
            variable = @fn.rangeTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}
