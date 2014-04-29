

window.config = config = {

  storageName: "sinewaves"

  resolution: 0.5

  mainLineWidth: 1.25

  # In pixels:
  minGridSpacing: 90
  hitTolerance: 10
  snapTolerance: 7

  outlineIndent: 16

  gridColor: "204,194,163"


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



  cursor: {
    text: "text"
    grab: "-webkit-grab"
    grabbing: "-webkit-grabbing"
    verticalScrub: "ns-resize"
    horizontalScrub: "ew-resize"
  }

}
