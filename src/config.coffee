

mixColors = (c1, c2, amount) ->
  amount1 = 1 - amount
  amount2 = amount
  numeric.add(numeric.mul(amount1, c1), numeric.mul(amount2, c2))

mainColor = [0.2, 0.2, 0.2, 1]
childColor = [0.8, 0.8, 0.8, 1]
selectedColor = [0, 0.6, 0.8, 1]
hoveredColor = mixColors(childColor, selectedColor, 0.3)



window.config = config = {

  storageName: "sinewaves"

  resolution: 0.5
  dimensions: 4

  mainLineWidth: 1.25

  # In pixels:
  minGridSpacing: 90
  hitTolerance: 10
  snapTolerance: 7

  outlineIndent: 16

  gridColor: "204,194,163"

  # colorMapPositive: ".80, .69, .36"
  # colorMapNegative: ".36, .47, .80"
  # colorMapPositive: ".84, .75, .47"
  # colorMapNegative: ".47, .56, .84"

  # colorMapZero:     util.hslToRgb(0, 0, 0.5).map(util.glslString).join(",")
  # colorMapPositive: util.hslToRgb(46, 1, 0.85).map(util.glslString).join(",")
  # colorMapNegative: util.hslToRgb(226, 1, 0.15).map(util.glslString).join(",")

  colorMapZero:     util.hslToRgb(0, 0, 0).map(util.glslString).join(",")
  colorMapPositive: util.hslToRgb(0, 0, 1).map(util.glslString).join(",")
  colorMapNegative: util.hslToRgb(226, 1, 0.4).map(util.glslString).join(",")


  style: {
    main: {
      strokeStyle: "#333"
      lineWidth: 1.25
    }
    default: {
      strokeStyle: "#ccc"
      lineWidth: 1.25
    }
    selected: {
      strokeStyle: "#09c"
      lineWidth: 1.25
    }
  }

  color: {
    main: mainColor
    child: childColor
    selected: selectedColor
    hovered: hoveredColor
  }



  cursor: {
    text: "text"
    grab: "-webkit-grab"
    grabbing: "-webkit-grabbing"
    verticalScrub: "ns-resize"
    horizontalScrub: "ew-resize"
  }

}
