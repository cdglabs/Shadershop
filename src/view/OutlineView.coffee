R.create "OutlineView",
  propTypes:
    definedFn: C.DefinedFn

  addCompoundFn: ->
    fn = new C.CompoundFn()
    UI.addChildFn(fn)

  render: ->
    R.div {className: "Outline"},
      R.OutlineChildrenView {
        compoundFn: @definedFn
        path: []
      }

      R.div {className: "TextButton", onClick: @addCompoundFn}, "Add"

      if UI.selectedChildFn
        R.OutlineControlsView {fn: UI.selectedChildFn}


# =============================================================================

R.create "OutlineChildrenView",
  propTypes:
    compoundFn: C.CompoundFn
    path: Array

  render: ->
    R.div {className: "OutlineChildren"},
      for childFn in @compoundFn.childFns
        R.OutlineItemView {
          childFn: childFn
          path: @path.concat(childFn)
        }


# =============================================================================

R.create "OutlineItemView",
  propTypes:
    childFn: C.ChildFn
    path: Array

  toggleExpanded: ->
    expanded = UI.isPathExpanded(@path)
    UI.setPathExpanded(@path, !expanded)

  handleMouseDown: (e) ->
    return unless e.target.classList.contains("OutlineRow")

    UI.preventDefault(e)

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
    path = @path

    parentCompoundFn = @lookup("compoundFn")

    util.onceDragConsummated e, =>
      UI.dragging = {
        cursor: "-webkit-grabbing"
        offset: offset
        placeholderHeight: myHeight
        childFn: childFn
        render: =>
          R.div {style: {width: myWidth, height: myHeight, overflow: "hidden", "background-color": "#fff"}},
            R.OutlineItemView {childFn, path, isDraggingCopy: true}
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
            index = parentCompoundFn.childFns.indexOf(childFn)
            parentCompoundFn.childFns.splice(index, 1)
            parentCompoundFn = null

          # Add self
          if bestDrop
            # console.log "here", bestDrop.outlineChildrenEl, bestDrop.outlineChildrenEl.dataFor
            parentCompoundFn = bestDrop.outlineChildrenEl.dataFor.compoundFn
            parentCompoundFn.childFns.splice(bestDrop.index, 0, childFn)


      }

  render: ->
    if !@isDraggingCopy and @childFn == UI.dragging?.childFn
      return R.div {className: "Placeholder", style: {height: UI.dragging.placeholderHeight}}

    canHaveChildren = @childFn.fn instanceof C.CompoundFn
    expanded = UI.isPathExpanded(@path)
    selected = (@childFn == UI.selectedChildFn)

    className = R.cx {
      OutlineItem: true
      Selected: selected
    }

    disclosureClassName = R.cx {
      DisclosureTriangle: true
      Expanded: expanded
    }

    R.div {className: className},
      R.div {className: "OutlineRow", onMouseDown: @handleMouseDown},
        if canHaveChildren
          R.div {className: "OutlineDisclosure"},
            R.div {className: disclosureClassName, onClick: @toggleExpanded}
        R.OutlineInternalsView {fn: @childFn.fn}

      if canHaveChildren and expanded
        R.OutlineChildrenView {
          compoundFn: @childFn.fn
          path: @path
        }


# =============================================================================

R.create "OutlineInternalsView",
  propTypes:
    fn: C.Fn

  render: ->
    R.div {className: "OutlineInternals"},
      if @fn instanceof C.BuiltInFn
        R.LabelView {fn: @fn} # TODO but not editable

      else if @fn instanceof C.DefinedFn
        R.LabelView {fn: @fn}

      else if @fn instanceof C.CompoundFn
        R.CombinerView {compoundFn: @fn}


# =============================================================================

R.create "LabelView",
  propTypes:
    fn: C.Fn

  handleInput: (newValue) ->
    @fn.label = newValue

  render: ->
    R.TextFieldView {
      className: "OutlineLabel"
      value: @fn.label
      onInput: @handleInput
    }


# =============================================================================

R.create "CombinerView",
  propTypes:
    compoundFn: C.CompoundFn

  handleChange: (e) ->
    value = e.target.selectedOptions[0].value
    @compoundFn.combiner = value

  render: ->
    R.div {},
      R.select {value: @compoundFn.combiner, onChange: @handleChange},
        R.option {value: "sum"}, "Add"
        R.option {value: "product"}, "Multiply"
        R.option {value: "composition"}, "Compose"












# =============================================================================

R.create "OutlineControlsView",
  propTypes:
    fn: C.ChildFn

  render: ->
    R.table {},
      R.tr {},
        @fn.domainTranslate.map (variable) =>
          R.td {},
            R.VariableView {variable}
        @fn.rangeTranslate.map (variable) =>
          R.td {},
            R.VariableView {variable}

      for coordIndex in [0...4]
        R.tr {},
          for rowIndex in [0...4]
            R.td {},
              R.VariableView {variable: @fn.domainTransform[rowIndex][coordIndex]}
          for rowIndex in [0...4]
            R.td {},
              R.VariableView {variable: @fn.rangeTransform[rowIndex][coordIndex]}
