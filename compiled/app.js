
(function(/*! Stitch !*/) {
  if (!this.require) {
    var modules = {}, cache = {}, require = function(name, root) {
      var path = expand(root, name), module = cache[path], fn;
      if (module) {
        return module.exports;
      } else if (fn = modules[path] || modules[path = expand(path, './index')]) {
        module = {id: path, exports: {}};
        try {
          cache[path] = module;
          fn(module.exports, function(name) {
            return require(name, dirname(path));
          }, module);
          return module.exports;
        } catch (err) {
          delete cache[path];
          throw err;
        }
      } else {
        throw 'module \'' + name + '\' not found';
      }
    }, expand = function(root, name) {
      var results = [], parts, part;
      if (/^\.\.?(\/|$)/.test(name)) {
        parts = [root, name].join('/').split('/');
      } else {
        parts = name.split('/');
      }
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part == '..') {
          results.pop();
        } else if (part != '.' && part != '') {
          results.push(part);
        }
      }
      return results.join('/');
    }, dirname = function(path) {
      return path.split('/').slice(0, -1).join('/');
    };
    this.require = function(name) {
      return require(name, '');
    }
    this.require.define = function(bundle) {
      for (var key in bundle)
        modules[key] = bundle[key];
    };
  }
  return this.require.define;
}).call(this)({"UI": function(exports, require, module) {(function() {
  var UI,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.UI = UI = new ((function() {
    function _Class() {
      this.handleWindowMouseUp = __bind(this.handleWindowMouseUp, this);
      this.handleWindowMouseMove = __bind(this.handleWindowMouseMove, this);
      this.dragging = null;
      this.autofocus = null;
      this.selectedFn = _.last(appRoot.fns);
      this.selectedChildFn = null;
      this.expandedPaths = {};
      this.registerEvents();
    }

    _Class.prototype.registerEvents = function() {
      window.addEventListener("mousemove", this.handleWindowMouseMove);
      return window.addEventListener("mouseup", this.handleWindowMouseUp);
    };

    _Class.prototype.preventDefault = function(e) {
      e.preventDefault();
      return util.selection.set(null);
    };

    _Class.prototype.handleWindowMouseMove = function(e) {
      var _ref;
      this.mousePosition = {
        x: e.clientX,
        y: e.clientY
      };
      return (_ref = this.dragging) != null ? typeof _ref.onMove === "function" ? _ref.onMove(e) : void 0 : void 0;
    };

    _Class.prototype.handleWindowMouseUp = function(e) {
      var _ref;
      if ((_ref = this.dragging) != null) {
        if (typeof _ref.onUp === "function") {
          _ref.onUp(e);
        }
      }
      this.dragging = null;
      if (this.hoverIsActive) {
        this.hoverData = null;
        return this.hoverIsActive = false;
      }
    };

    _Class.prototype.getElementUnderMouse = function() {
      var draggingOverlayEl, el;
      draggingOverlayEl = document.querySelector(".draggingOverlay");
      if (draggingOverlayEl != null) {
        draggingOverlayEl.style.pointerEvents = "none";
      }
      el = document.elementFromPoint(this.mousePosition.x, this.mousePosition.y);
      if (draggingOverlayEl != null) {
        draggingOverlayEl.style.pointerEvents = "";
      }
      return el;
    };

    _Class.prototype.getViewUnderMouse = function() {
      var el;
      el = this.getElementUnderMouse();
      el = el != null ? el.closest(function(el) {
        return el.dataFor != null;
      }) : void 0;
      return el != null ? el.dataFor : void 0;
    };

    _Class.prototype.selectFn = function(fn) {
      if (!(fn instanceof C.CompoundFn)) {
        return;
      }
      this.selectedFn = fn;
      return this.selectedChildFn = null;
    };

    _Class.prototype.selectChildFn = function(childFn) {
      return this.selectedChildFn = childFn;
    };

    _Class.prototype.addFn = function(appRoot) {
      var fn;
      fn = new C.CompoundFn();
      appRoot.fns.push(fn);
      return this.selectFn(fn);
    };

    _Class.prototype.addChildFn = function(fn) {
      var childFn;
      childFn = new C.ChildFn();
      childFn.fn = fn;
      this.selectedFn.childFns.push(childFn);
      return this.selectChildFn(childFn);
    };

    _Class.prototype.removeChildFn = function(fn, childFnIndex) {
      var removedChildFn;
      removedChildFn = fn.childFns.splice(childFnIndex, 1)[0];
      if (this.selectedChildFn === removedChildFn) {
        return this.selectChildFn(null);
      }
    };

    _Class.prototype.getPathString = function(path) {
      var pathIds, pathString;
      pathIds = path.map(function(childFn) {
        return C.id(childFn);
      });
      return pathString = pathIds.join(",");
    };

    _Class.prototype.isPathExpanded = function(path) {
      var pathString;
      pathString = this.getPathString(path);
      return this.expandedPaths[pathString];
    };

    _Class.prototype.setPathExpanded = function(path, expanded) {
      var pathString;
      pathString = this.getPathString(path);
      return this.expandedPaths[pathString] = expanded;
    };

    _Class.prototype.startVariableScrub = function(opts) {
      var cursor, onMove, variable;
      variable = opts.variable;
      cursor = opts.cursor;
      onMove = opts.onMove;
      return UI.dragging = {
        cursor: cursor,
        onMove: (function(_this) {
          return function(e) {
            var newValueString;
            newValueString = onMove(e);
            return variable.valueString = newValueString;
          };
        })(this)
      };
    };

    _Class.prototype.setAutoFocus = function(opts) {
      if (opts.descendantOf == null) {
        opts.descendantOf = [];
      }
      if (!_.isArray(opts.descendantOf)) {
        opts.descendantOf = [opts.descendantOf];
      }
      if (opts.props == null) {
        opts.props = {};
      }
      if (opts.location == null) {
        opts.location = "end";
      }
      return this.autofocus = opts;
    };

    _Class.prototype.attemptAutoFocus = function(textFieldView) {
      var el, matchesDescendantOf, matchesProps;
      if (!this.autofocus) {
        return;
      }
      matchesDescendantOf = _.every(this.autofocus.descendantOf, (function(_this) {
        return function(ancestorView) {
          return textFieldView.lookupView(ancestorView);
        };
      })(this));
      if (!matchesDescendantOf) {
        return;
      }
      matchesProps = _.every(this.autofocus.props, (function(_this) {
        return function(propValue, propName) {
          return textFieldView.lookup(propName) === propValue;
        };
      })(this));
      if (!matchesProps) {
        return;
      }
      el = textFieldView.getDOMNode();
      if (this.autofocus.location === "start") {
        util.selection.setAtStart(el);
      } else if (this.autofocus.location === "end") {
        util.selection.setAtEnd(el);
      }
      return this.autofocus = null;
    };

    return _Class;

  })());

}).call(this);
}, "config": function(exports, require, module) {(function() {
  var config;

  window.config = config = {
    storageName: "sinewaves",
    resolution: 0.5,
    mainLineWidth: 1.25,
    minGridSpacing: 90,
    hitTolerance: 10,
    snapTolerance: 7,
    outlineIndent: 16,
    gridColor: "204,194,163",
    style: {
      main: {
        strokeStyle: "#333",
        lineWidth: 1.25
      },
      "default": {
        strokeStyle: "#ccc",
        lineWidth: 1.25
      },
      selected: {
        strokeStyle: "#09c",
        lineWidth: 1.25
      }
    },
    cursor: {
      text: "text",
      grab: "-webkit-grab",
      grabbing: "-webkit-grabbing",
      verticalScrub: "ns-resize",
      horizontalScrub: "ew-resize"
    }
  };

}).call(this);
}, "main": function(exports, require, module) {(function() {
  var eventName, json, refresh, refreshEventNames, refreshView, saveState, storageName, willRefreshNextFrame, _i, _len;

  require("./config");

  require("./util/util");

  require("./model/C");

  require("./view/R");

  storageName = config.storageName;

  window.reset = function() {
    delete window.localStorage[storageName];
    return location.reload();
  };

  if (json = window.localStorage[storageName]) {
    json = JSON.parse(json);
    window.appRoot = C.reconstruct(json);
  } else {
    window.appRoot = new C.AppRoot();
  }

  saveState = function() {
    json = C.deconstruct(appRoot);
    json = JSON.stringify(json);
    return window.localStorage[storageName] = json;
  };

  window.save = function() {
    return window.localStorage[storageName];
  };

  window.restore = function(jsonString) {
    if (!_.isString(jsonString)) {
      jsonString = JSON.stringify(jsonString);
    }
    window.localStorage[storageName] = jsonString;
    return location.reload();
  };

  require("./UI");

  willRefreshNextFrame = false;

  refresh = function() {
    if (willRefreshNextFrame) {
      return;
    }
    willRefreshNextFrame = true;
    return requestAnimationFrame(function() {
      refreshView();
      saveState();
      return willRefreshNextFrame = false;
    });
  };

  refreshView = function() {
    var appRootEl;
    appRootEl = document.querySelector("#AppRoot");
    return React.renderComponent(R.AppRootView({
      appRoot: appRoot
    }), appRootEl);
  };

  refreshEventNames = ["mousedown", "mousemove", "mouseup", "keydown", "scroll", "change", "wheel", "mousewheel"];

  for (_i = 0, _len = refreshEventNames.length; _i < _len; _i++) {
    eventName = refreshEventNames[_i];
    window.addEventListener(eventName, refresh);
  }

  refresh();

  if (location.protocol === "file:") {
    document.styleSheets.start_autoreload(1000);
  }

}).call(this);
}, "model/C": function(exports, require, module) {(function() {
  var C, className, constructor,
    __hasProp = {}.hasOwnProperty;

  window.C = C = {};

  require("./model");

  for (className in C) {
    if (!__hasProp.call(C, className)) continue;
    constructor = C[className];
    constructor.prototype.__className = className;
  }

  C._idCounter = 0;

  C._assignId = function(obj) {
    var id;
    this._idCounter++;
    id = "id" + this._idCounter + Date.now() + Math.floor(1e9 * Math.random());
    return obj.__id = id;
  };

  C.id = function(obj) {
    var _ref;
    return (_ref = obj.__id) != null ? _ref : C._assignId(obj);
  };

  C.deconstruct = function(object) {
    var objects, root, serialize;
    objects = {};
    serialize = (function(_this) {
      return function(object, force) {
        var entry, id, key, result, value, _i, _len;
        if (force == null) {
          force = false;
        }
        if (!force && (object != null ? object.__className : void 0)) {
          id = C.id(object);
          if (!objects[id]) {
            objects[id] = serialize(object, true);
          }
          return {
            __ref: id
          };
        }
        if (_.isArray(object)) {
          result = [];
          for (_i = 0, _len = object.length; _i < _len; _i++) {
            entry = object[_i];
            result.push(serialize(entry));
          }
          return result;
        }
        if (_.isObject(object)) {
          result = {};
          for (key in object) {
            if (!__hasProp.call(object, key)) continue;
            value = object[key];
            result[key] = serialize(value);
          }
          if (object.__className) {
            result.__className = object.__className;
          }
          return result;
        }
        return object != null ? object : null;
      };
    })(this);
    root = serialize(object);
    return {
      objects: objects,
      root: root
    };
  };

  C.reconstruct = function(_arg) {
    var constructObject, constructedObjects, derefObject, id, object, objects, root;
    objects = _arg.objects, root = _arg.root;
    constructedObjects = {};
    constructObject = (function(_this) {
      return function(object) {
        var classConstructor, constructedObject, key, value;
        className = object.__className;
        classConstructor = C[className];
        constructedObject = new classConstructor();
        for (key in object) {
          if (!__hasProp.call(object, key)) continue;
          value = object[key];
          if (key === "__className") {
            continue;
          }
          constructedObject[key] = value;
        }
        return constructedObject;
      };
    })(this);
    for (id in objects) {
      if (!__hasProp.call(objects, id)) continue;
      object = objects[id];
      constructedObjects[id] = constructObject(object);
    }
    derefObject = (function(_this) {
      return function(object) {
        var key, value, _results;
        if (!_.isObject(object)) {
          return;
        }
        _results = [];
        for (key in object) {
          if (!__hasProp.call(object, key)) continue;
          value = object[key];
          if (id = value != null ? value.__ref : void 0) {
            _results.push(object[key] = constructedObjects[id]);
          } else {
            _results.push(derefObject(value));
          }
        }
        return _results;
      };
    })(this);
    for (id in constructedObjects) {
      if (!__hasProp.call(constructedObjects, id)) continue;
      object = constructedObjects[id];
      derefObject(object);
    }
    return constructedObjects[root.__ref];
  };

}).call(this);
}, "model/model": function(exports, require, module) {(function() {
  var builtIn,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  C.Variable = (function() {
    function Variable(valueString) {
      this.valueString = valueString != null ? valueString : "0";
      this.getValue();
    }

    Variable.prototype.getValue = function() {
      var value;
      value = this._lastWorkingValue;
      try {
        if (/^[-+]?[0-9]*\.?[0-9]+$/.test(this.valueString)) {
          value = parseFloat(this.valueString);
        } else {
          value = util.evaluate(this.valueString);
        }
      } catch (_error) {}
      this._lastWorkingValue = value;
      return value;
    };

    return Variable;

  })();

  C.Fn = (function() {
    function Fn() {}

    return Fn;

  })();

  C.BuiltInFn = (function(_super) {
    __extends(BuiltInFn, _super);

    function BuiltInFn(fnName, label) {
      this.fnName = fnName;
      this.label = label;
    }

    BuiltInFn.prototype.getExprString = function(parameter) {
      if (this.fnName === "identity") {
        return parameter;
      }
      return "" + this.fnName + "(" + parameter + ")";
    };

    return BuiltInFn;

  })(C.Fn);

  C.CompoundFn = (function(_super) {
    __extends(CompoundFn, _super);

    function CompoundFn() {
      this.label = "";
      this.combiner = "sum";
      this.childFns = [];
      this.bounds = {
        xMin: -6,
        xMax: 6,
        yMin: -6,
        yMax: 6
      };
    }

    CompoundFn.prototype.getExprString = function(parameter) {
      var childExprStrings, childFn, exprString, _i, _len, _ref;
      if (this.combiner === "composition") {
        exprString = parameter;
        _ref = this.childFns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childFn = _ref[_i];
          exprString = childFn.getExprString(exprString);
        }
        return exprString;
      }
      childExprStrings = this.childFns.map((function(_this) {
        return function(childFn) {
          return childFn.getExprString(parameter);
        };
      })(this));
      if (this.combiner === "sum") {
        childExprStrings.unshift("0");
        return "(" + childExprStrings.join(" + ") + ")";
      }
      if (this.combiner === "product") {
        childExprStrings.unshift("1");
        return "(" + childExprStrings.join(" * ") + ")";
      }
    };

    return CompoundFn;

  })(C.Fn);

  C.ChildFn = (function(_super) {
    __extends(ChildFn, _super);

    function ChildFn() {
      this.fn = null;
      this.domainTranslate = new C.Variable("0");
      this.domainScale = new C.Variable("1");
      this.rangeTranslate = new C.Variable("0");
      this.rangeScale = new C.Variable("1");
    }

    ChildFn.prototype.getExprString = function(parameter) {
      var domainScale, domainTranslate, exprString, rangeScale, rangeTranslate;
      domainTranslate = this.domainTranslate.getValue();
      domainScale = this.domainScale.getValue();
      rangeTranslate = this.rangeTranslate.getValue();
      rangeScale = this.rangeScale.getValue();
      exprString = "((" + parameter + " - " + domainTranslate + ") / " + domainScale + ")";
      exprString = this.fn.getExprString(exprString);
      exprString = "(" + exprString + " * " + rangeScale + " + " + rangeTranslate + ")";
      return exprString;
    };

    return ChildFn;

  })(C.Fn);

  C.AppRoot = (function() {
    function AppRoot() {
      this.fns = [new C.CompoundFn()];
    }

    return AppRoot;

  })();

  window.builtIn = builtIn = {};

  builtIn.fns = [new C.BuiltInFn("identity", "Line"), new C.BuiltInFn("abs", "Abs"), new C.BuiltInFn("fract", "Fract"), new C.BuiltInFn("floor", "Floor"), new C.BuiltInFn("sin", "Sine")];

}).call(this);
}, "util/canvas": function(exports, require, module) {(function() {
  var canvasBounds, clear, drawCartesian, drawGrid, drawHorizontal, drawLine, drawVertical, getSpacing, lerp, setStyle, ticks,
    __hasProp = {}.hasOwnProperty;

  lerp = util.lerp;

  canvasBounds = function(ctx) {
    var canvas;
    canvas = ctx.canvas;
    return {
      cxMin: 0,
      cxMax: canvas.width,
      cyMin: canvas.height,
      cyMax: 0,
      width: canvas.width,
      height: canvas.height
    };
  };

  clear = function(ctx) {
    var canvas;
    canvas = ctx.canvas;
    return ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  setStyle = function(ctx, styleOpts) {
    var key, value, _results;
    _results = [];
    for (key in styleOpts) {
      if (!__hasProp.call(styleOpts, key)) continue;
      value = styleOpts[key];
      _results.push(ctx[key] = value);
    }
    return _results;
  };

  drawCartesian = function(ctx, opts) {
    var cx, cxMax, cxMin, cy, cyMax, cyMin, dCy, fn, i, lastCx, lastCy, lastSample, testDiscontinuity, x, xMax, xMin, y, yMax, yMin, _i, _ref, _ref1;
    xMin = opts.xMin;
    xMax = opts.xMax;
    yMin = opts.yMin;
    yMax = opts.yMax;
    fn = opts.fn;
    testDiscontinuity = (_ref = opts.testDiscontinuity) != null ? _ref : function() {
      return false;
    };
    _ref1 = canvasBounds(ctx), cxMin = _ref1.cxMin, cxMax = _ref1.cxMax, cyMin = _ref1.cyMin, cyMax = _ref1.cyMax;
    ctx.beginPath();
    lastSample = cxMax / config.resolution;
    lastCx = null;
    lastCy = null;
    dCy = null;
    for (i = _i = 0; 0 <= lastSample ? _i <= lastSample : _i >= lastSample; i = 0 <= lastSample ? ++_i : --_i) {
      cx = i * config.resolution;
      x = lerp(cx, cxMin, cxMax, xMin, xMax);
      y = fn(x);
      cy = lerp(y, yMin, yMax, cyMin, cyMax);
      if (lastCy == null) {
        ctx.moveTo(cx, cy);
      }
      if (dCy != null) {
        if (Math.abs((cy - lastCy) - dCy) > .000001) {
          ctx.lineTo(lastCx, lastCy);
        }
      }
      if (lastCy != null) {
        dCy = cy - lastCy;
      }
      lastCx = cx;
      lastCy = cy;
    }
    return ctx.lineTo(cx, cy);
  };

  drawVertical = function(ctx, opts) {
    var cx, cxMax, cxMin, cyMax, cyMin, x, xMax, xMin, _ref;
    xMin = opts.xMin;
    xMax = opts.xMax;
    x = opts.x;
    _ref = canvasBounds(ctx), cxMin = _ref.cxMin, cxMax = _ref.cxMax, cyMin = _ref.cyMin, cyMax = _ref.cyMax;
    ctx.beginPath();
    cx = lerp(x, xMin, xMax, cxMin, cxMax);
    ctx.moveTo(cx, cyMin);
    return ctx.lineTo(cx, cyMax);
  };

  drawHorizontal = function(ctx, opts) {
    var cxMax, cxMin, cy, cyMax, cyMin, y, yMax, yMin, _ref;
    yMin = opts.yMin;
    yMax = opts.yMax;
    y = opts.y;
    _ref = canvasBounds(ctx), cxMin = _ref.cxMin, cxMax = _ref.cxMax, cyMin = _ref.cyMin, cyMax = _ref.cyMax;
    ctx.beginPath();
    cy = lerp(y, yMin, yMax, cyMin, cyMax);
    ctx.moveTo(cxMin, cy);
    return ctx.lineTo(cxMax, cy);
  };

  ticks = function(spacing, min, max) {
    var first, last, x, _i, _results;
    first = Math.ceil(min / spacing);
    last = Math.floor(max / spacing);
    _results = [];
    for (x = _i = first; first <= last ? _i <= last : _i >= last; x = first <= last ? ++_i : --_i) {
      _results.push(x * spacing);
    }
    return _results;
  };

  drawLine = function(ctx, _arg, _arg1) {
    var x1, x2, y1, y2;
    x1 = _arg[0], y1 = _arg[1];
    x2 = _arg1[0], y2 = _arg1[1];
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    return ctx.stroke();
  };

  getSpacing = function(opts) {
    var div, height, largeSpacing, minSpacing, smallSpacing, width, xMax, xMin, xMinSpacing, xSize, yMax, yMin, yMinSpacing, ySize, z, _ref, _ref1;
    xMin = opts.xMin, xMax = opts.xMax, yMin = opts.yMin, yMax = opts.yMax;
    width = (_ref = opts.width) != null ? _ref : config.mainPlotWidth;
    height = (_ref1 = opts.height) != null ? _ref1 : config.mainPlotHeight;
    xSize = xMax - xMin;
    ySize = yMax - yMin;
    xMinSpacing = (xSize / width) * config.minGridSpacing;
    yMinSpacing = (ySize / height) * config.minGridSpacing;
    minSpacing = Math.max(xMinSpacing, yMinSpacing);

    /*
    need to determine:
      largeSpacing = {1, 2, or 5} * 10^n
      smallSpacing = divide largeSpacing by 4 (if 1 or 2) or 5 (if 5)
    largeSpacing must be greater than minSpacing
     */
    div = 4;
    largeSpacing = z = Math.pow(10, Math.ceil(Math.log(minSpacing) / Math.log(10)));
    if (z / 5 > minSpacing) {
      largeSpacing = z / 5;
    } else if (z / 2 > minSpacing) {
      largeSpacing = z / 2;
      div = 5;
    }
    smallSpacing = largeSpacing / div;
    return {
      largeSpacing: largeSpacing,
      smallSpacing: smallSpacing
    };
  };

  drawGrid = function(ctx, opts) {
    var axesColor, axesOpacity, color, cx, cxMax, cxMin, cy, cyMax, cyMin, fromLocal, height, labelColor, labelDistance, labelOpacity, largeSpacing, majorColor, majorOpacity, minorColor, minorOpacity, smallSpacing, text, textHeight, toLocal, width, x, xMax, xMin, y, yMax, yMin, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    xMin = opts.xMin;
    xMax = opts.xMax;
    yMin = opts.yMin;
    yMax = opts.yMax;
    _ref = canvasBounds(ctx), cxMin = _ref.cxMin, cxMax = _ref.cxMax, cyMin = _ref.cyMin, cyMax = _ref.cyMax, width = _ref.width, height = _ref.height;
    _ref1 = getSpacing({
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
      width: width,
      height: height
    }), largeSpacing = _ref1.largeSpacing, smallSpacing = _ref1.smallSpacing;
    toLocal = function(_arg) {
      var cx, cy;
      cx = _arg[0], cy = _arg[1];
      return [lerp(cx, cxMin, cxMax, xMin, xMax), lerp(cy, cyMin, cyMax, yMin, yMax)];
    };
    fromLocal = function(_arg) {
      var x, y;
      x = _arg[0], y = _arg[1];
      return [lerp(x, xMin, xMax, cxMin, cxMax), lerp(y, yMin, yMax, cyMin, cyMax)];
    };
    labelDistance = 5;
    color = config.gridColor;
    minorOpacity = 0.075;
    majorOpacity = 0.1;
    axesOpacity = 0.25;
    labelOpacity = 1.0;
    textHeight = 12;
    minorColor = "rgba(" + color + ", " + minorOpacity + ")";
    majorColor = "rgba(" + color + ", " + majorOpacity + ")";
    axesColor = "rgba(" + color + ", " + axesOpacity + ")";
    labelColor = "rgba(" + color + ", " + labelOpacity + ")";
    ctx.save();
    ctx.lineWidth = 1;
    ctx.strokeStyle = minorColor;
    _ref2 = ticks(smallSpacing, xMin, xMax);
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      x = _ref2[_i];
      drawLine(ctx, fromLocal([x, yMin]), fromLocal([x, yMax]));
    }
    _ref3 = ticks(smallSpacing, yMin, yMax);
    for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
      y = _ref3[_j];
      drawLine(ctx, fromLocal([xMin, y]), fromLocal([xMax, y]));
    }
    ctx.strokeStyle = majorColor;
    _ref4 = ticks(largeSpacing, xMin, xMax);
    for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
      x = _ref4[_k];
      drawLine(ctx, fromLocal([x, yMin]), fromLocal([x, yMax]));
    }
    _ref5 = ticks(largeSpacing, yMin, yMax);
    for (_l = 0, _len3 = _ref5.length; _l < _len3; _l++) {
      y = _ref5[_l];
      drawLine(ctx, fromLocal([xMin, y]), fromLocal([xMax, y]));
    }
    ctx.strokeStyle = axesColor;
    drawLine(ctx, fromLocal([0, yMin]), fromLocal([0, yMax]));
    drawLine(ctx, fromLocal([xMin, 0]), fromLocal([xMax, 0]));
    ctx.font = "" + textHeight + "px verdana";
    ctx.fillStyle = labelColor;
    ctx.textAlign = "center";
    ctx.textBaseline = "top";
    _ref6 = ticks(largeSpacing, xMin, xMax);
    for (_m = 0, _len4 = _ref6.length; _m < _len4; _m++) {
      x = _ref6[_m];
      if (x !== 0) {
        text = parseFloat(x.toPrecision(12)).toString();
        _ref7 = fromLocal([x, 0]), cx = _ref7[0], cy = _ref7[1];
        cy += labelDistance;
        if (cy < labelDistance) {
          cy = labelDistance;
        }
        if (cy + textHeight + labelDistance > height) {
          cy = height - labelDistance - textHeight;
        }
        ctx.fillText(text, cx, cy);
      }
    }
    ctx.textAlign = "left";
    ctx.textBaseline = "middle";
    _ref8 = ticks(largeSpacing, yMin, yMax);
    for (_n = 0, _len5 = _ref8.length; _n < _len5; _n++) {
      y = _ref8[_n];
      if (y !== 0) {
        text = parseFloat(y.toPrecision(12)).toString();
        _ref9 = fromLocal([0, y]), cx = _ref9[0], cy = _ref9[1];
        cx += labelDistance;
        if (cx < labelDistance) {
          cx = labelDistance;
        }
        if (cx + ctx.measureText(text).width + labelDistance > width) {
          cx = width - labelDistance - ctx.measureText(text).width;
        }
        ctx.fillText(text, cx, cy);
      }
    }
    return ctx.restore();
  };

  util.canvas = {
    lerp: lerp,
    clear: clear,
    setStyle: setStyle,
    drawCartesian: drawCartesian,
    drawVertical: drawVertical,
    drawHorizontal: drawHorizontal,
    getSpacing: getSpacing,
    drawGrid: drawGrid
  };

}).call(this);
}, "util/evaluate": function(exports, require, module) {(function() {
  var abs, add, ceil, cos, div, evaluate, evaluateFn, floor, fract, identity, max, min, mul, pow, sin, sqrt, sub;

  evaluate = function(jsString) {
    return eval(jsString);
  };

  evaluateFn = function(exprString) {
    return evaluate("(function (x) { return " + this.exprString + "; })");
  };

  identity = function(a) {
    return a;
  };

  add = function(a, b) {
    return a + b;
  };

  sub = function(a, b) {
    return a - b;
  };

  mul = function(a, b) {
    return a * b;
  };

  div = function(a, b) {
    return a / b;
  };

  abs = Math.abs;

  fract = function(a) {
    return a - Math.floor(a);
  };

  floor = Math.floor;

  ceil = Math.ceil;

  min = Math.min;

  max = Math.max;

  sin = Math.sin;

  cos = Math.cos;

  sqrt = Math.sqrt;

  pow = function(a, b) {
    return Math.pow(Math.abs(a), b);
  };

  util.evaluate = evaluate;

  util.evaluateFn = evaluateFn;

}).call(this);
}, "util/selection": function(exports, require, module) {(function() {
  var afterSelection, beforeSelection, findEditingHost, focusBody, get, getHost, isAtEnd, isAtStart, set, setAll, setAtEnd, setAtStart;

  get = function() {
    var range, selection;
    selection = window.getSelection();
    if (selection.rangeCount > 0) {
      range = selection.getRangeAt(0);
      return range;
    } else {
      return null;
    }
  };

  set = function(range) {
    var host, selection;
    selection = window.getSelection();
    if (range == null) {
      return selection.removeAllRanges();
    } else {
      host = findEditingHost(range.commonAncestorContainer);
      if (host != null) {
        host.focus();
      }
      selection.removeAllRanges();
      return selection.addRange(range);
    }
  };

  getHost = function() {
    var selectedRange;
    selectedRange = get();
    if (!selectedRange) {
      return null;
    }
    return findEditingHost(selectedRange.commonAncestorContainer);
  };

  beforeSelection = function() {
    var host, range, selectedRange;
    selectedRange = get();
    if (!selectedRange) {
      return null;
    }
    host = getHost();
    range = document.createRange();
    range.selectNodeContents(host);
    range.setEnd(selectedRange.startContainer, selectedRange.startOffset);
    return range;
  };

  afterSelection = function() {
    var host, range, selectedRange;
    selectedRange = get();
    if (!selectedRange) {
      return null;
    }
    host = getHost();
    range = document.createRange();
    range.selectNodeContents(host);
    range.setStart(selectedRange.endContainer, selectedRange.endOffset);
    return range;
  };

  isAtStart = function() {
    var _ref;
    if (!((_ref = get()) != null ? _ref.collapsed : void 0)) {
      return false;
    }
    return beforeSelection().toString() === "";
  };

  isAtEnd = function() {
    var _ref;
    if (!((_ref = get()) != null ? _ref.collapsed : void 0)) {
      return false;
    }
    return afterSelection().toString() === "";
  };

  setAtStart = function(el) {
    var range;
    range = document.createRange();
    range.selectNodeContents(el);
    range.collapse(true);
    return set(range);
  };

  setAtEnd = function(el) {
    var range;
    range = document.createRange();
    range.selectNodeContents(el);
    range.collapse(false);
    return set(range);
  };

  setAll = function(el) {
    var range;
    range = document.createRange();
    range.selectNodeContents(el);
    return set(range);
  };

  focusBody = function() {
    var body;
    body = document.body;
    if (!body.hasAttribute("tabindex")) {
      body.setAttribute("tabindex", "0");
    }
    return body.focus();
  };

  findEditingHost = function(node) {
    if (node == null) {
      return null;
    }
    if (node.nodeType !== Node.ELEMENT_NODE) {
      return findEditingHost(node.parentNode);
    }
    if (!node.isContentEditable) {
      return null;
    }
    if (!node.parentNode.isContentEditable) {
      return node;
    }
    return findEditingHost(node.parentNode);
  };

  util.selection = {
    get: get,
    set: set,
    getHost: getHost,
    beforeSelection: beforeSelection,
    afterSelection: afterSelection,
    isAtStart: isAtStart,
    isAtEnd: isAtEnd,
    setAtStart: setAtStart,
    setAtEnd: setAtEnd,
    setAll: setAll
  };

}).call(this);
}, "util/util": function(exports, require, module) {(function() {
  var util, _base, _ref, _ref1;

  window.util = util = {};

  _.concatMap = function(array, fn) {
    return _.flatten(_.map(array, fn), true);
  };

  if ((_base = Element.prototype).matches == null) {
    _base.matches = (_ref = (_ref1 = Element.prototype.webkitMatchesSelector) != null ? _ref1 : Element.prototype.mozMatchesSelector) != null ? _ref : Element.prototype.oMatchesSelector;
  }

  Element.prototype.closest = function(selector) {
    var fn, parent;
    if (_.isString(selector)) {
      fn = function(el) {
        return el.matches(selector);
      };
    } else {
      fn = selector;
    }
    if (fn(this)) {
      return this;
    } else {
      parent = this.parentNode;
      if ((parent != null) && parent.nodeType === Node.ELEMENT_NODE) {
        return parent.closest(fn);
      } else {
        return void 0;
      }
    }
  };

  Element.prototype.getMarginRect = function() {
    var rect, result, style;
    rect = this.getBoundingClientRect();
    style = window.getComputedStyle(this);
    result = {
      top: rect.top - parseInt(style["margin-top"], 10),
      left: rect.left - parseInt(style["margin-left"], 10),
      bottom: rect.bottom + parseInt(style["margin-bottom"], 10),
      right: rect.right + parseInt(style["margin-right"], 10)
    };
    result.width = result.right - result.left;
    result.height = result.bottom - result.top;
    return result;
  };

  Element.prototype.isOnScreen = function() {
    var horizontal, rect, screenHeight, screenWidth, vertical, _ref2, _ref3, _ref4, _ref5;
    rect = this.getBoundingClientRect();
    screenWidth = window.innerWidth;
    screenHeight = window.innerHeight;
    vertical = (0 <= (_ref2 = rect.top) && _ref2 <= screenHeight) || (0 <= (_ref3 = rect.bottom) && _ref3 <= screenHeight);
    horizontal = (0 <= (_ref4 = rect.left) && _ref4 <= screenWidth) || (0 <= (_ref5 = rect.right) && _ref5 <= screenWidth);
    return vertical && horizontal;
  };

  util.lerp = function(x, dMin, dMax, rMin, rMax) {
    var ratio;
    ratio = (x - dMin) / (dMax - dMin);
    return ratio * (rMax - rMin) + rMin;
  };

  util.floatToString = function(value, precision, removeExtraZeros) {
    var digitPrecision, string;
    if (precision == null) {
      precision = 0.1;
    }
    if (removeExtraZeros == null) {
      removeExtraZeros = false;
    }
    if (precision < 1) {
      digitPrecision = -Math.round(Math.log(precision) / Math.log(10));
      string = value.toFixed(digitPrecision);
    } else {
      string = value.toFixed(0);
    }
    if (removeExtraZeros) {
      string = string.replace(/\.?0*$/, "");
    }
    if (/^-0(\.0*)?$/.test(string)) {
      string = string.slice(1);
    }
    return string;
  };

  util.onceDragConsummated = function(downEvent, callback, notConsummatedCallback) {
    var consummated, handleMove, handleUp, originalX, originalY, removeListeners;
    if (notConsummatedCallback == null) {
      notConsummatedCallback = null;
    }
    consummated = false;
    originalX = downEvent.clientX;
    originalY = downEvent.clientY;
    handleMove = function(moveEvent) {
      var d, dx, dy;
      dx = moveEvent.clientX - originalX;
      dy = moveEvent.clientY - originalY;
      d = Math.max(Math.abs(dx), Math.abs(dy));
      if (d > 3) {
        consummated = true;
        removeListeners();
        return typeof callback === "function" ? callback(moveEvent) : void 0;
      }
    };
    handleUp = function(upEvent) {
      if (!consummated) {
        if (typeof notConsummatedCallback === "function") {
          notConsummatedCallback(upEvent);
        }
      }
      return removeListeners();
    };
    removeListeners = function() {
      window.removeEventListener("mousemove", handleMove);
      return window.removeEventListener("mouseup", handleUp);
    };
    window.addEventListener("mousemove", handleMove);
    return window.addEventListener("mouseup", handleUp);
  };

  require("./selection");

  require("./canvas");

  require("./evaluate");

}).call(this);
}, "view/AppRootView": function(exports, require, module) {(function() {
  R.create("AppRootView", {
    propTypes: {
      appRoot: C.AppRoot
    },
    render: function() {
      return R.div({}, R.DefinitionsView({
        appRoot: this.appRoot
      }), R.MainPlotView({
        fn: UI.selectedFn
      }), R.OutlineView({
        compoundFn: UI.selectedFn
      }));
    }
  });

}).call(this);
}, "view/DefinitionsView": function(exports, require, module) {(function() {
  var defaultBounds;

  R.create("DefinitionsView", {
    propTypes: {
      appRoot: C.AppRoot
    },
    addFn: function() {
      return UI.addFn(this.appRoot);
    },
    render: function() {
      return R.div({
        className: "Definitions"
      }, builtIn.fns.map((function(_this) {
        return function(fn) {
          return R.DefinitionView({
            fn: fn
          });
        };
      })(this)), R.div({
        className: "Divider"
      }), this.appRoot.fns.map((function(_this) {
        return function(fn) {
          return R.DefinitionView({
            fn: fn
          });
        };
      })(this)), R.div({
        className: "AddDefinition"
      }, R.button({
        className: "AddButton",
        onClick: this.addFn
      })));
    }
  });

  defaultBounds = {
    xMin: -6,
    xMax: 6,
    yMin: -6,
    yMax: 6
  };

  R.create("DefinitionView", {
    propTypes: {
      fn: C.Fn
    },
    handleMouseDown: function(e) {
      var addChildFn, selectFn;
      UI.preventDefault(e);
      addChildFn = (function(_this) {
        return function() {
          return UI.addChildFn(_this.fn);
        };
      })(this);
      selectFn = (function(_this) {
        return function() {
          return UI.selectFn(_this.fn);
        };
      })(this);
      return util.onceDragConsummated(e, addChildFn, selectFn);
    },
    handleLabelInput: function(newValue) {
      return this.fn.label = newValue;
    },
    render: function() {
      var bounds, className, exprString, fnString;
      exprString = this.fn.getExprString("x");
      fnString = "(function (x) { return " + exprString + "; })";
      if (this.fn instanceof C.BuiltInFn) {
        bounds = defaultBounds;
      } else {
        bounds = this.fn.bounds;
      }
      className = R.cx({
        Definition: true,
        Selected: UI.selectedFn === this.fn
      });
      return R.div({
        className: className
      }, R.div({
        className: "PlotContainer",
        onMouseDown: this.handleMouseDown
      }, R.GridView({
        bounds: bounds
      }), R.PlotCartesianView({
        bounds: bounds,
        fnString: fnString,
        style: config.style.main
      })), this.fn instanceof C.BuiltInFn ? R.div({
        className: "Label"
      }, this.fn.label) : R.TextFieldView({
        className: "Label",
        value: this.fn.label,
        onInput: this.handleLabelInput
      }));
    }
  });

}).call(this);
}, "view/MainPlotView": function(exports, require, module) {(function() {
  R.create("MainPlotView", {
    propTypes: {
      fn: C.Fn
    },
    getLocalMouseCoords: function() {
      var bounds, rect, x, y;
      bounds = this.fn.bounds;
      rect = this.getDOMNode().getBoundingClientRect();
      x = util.lerp(UI.mousePosition.x, rect.left, rect.right, bounds.xMin, bounds.xMax);
      y = util.lerp(UI.mousePosition.y, rect.bottom, rect.top, bounds.yMin, bounds.yMax);
      return {
        x: x,
        y: y
      };
    },
    changeSelection: function() {
      var bounds, childFn, distance, exprString, fn, fnString, found, pixelWidth, rect, x, y, _i, _len, _ref, _ref1;
      _ref = this.getLocalMouseCoords(), x = _ref.x, y = _ref.y;
      rect = this.getDOMNode().getBoundingClientRect();
      bounds = this.fn.bounds;
      pixelWidth = (bounds.xMax - bounds.xMin) / rect.width;
      found = null;
      _ref1 = this.fn.childFns;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        childFn = _ref1[_i];
        exprString = childFn.getExprString("x");
        fnString = "(function (x) { return " + exprString + "; })";
        fn = util.evaluate(fnString);
        distance = Math.abs(y - fn(x));
        if (distance < config.hitTolerance * pixelWidth) {
          found = childFn;
        }
      }
      return UI.selectChildFn(found);
    },
    startPan: function(e) {
      var originalBounds, originalX, originalY, rect, xScale, yScale;
      originalX = e.clientX;
      originalY = e.clientY;
      originalBounds = {
        xMin: this.fn.bounds.xMin,
        xMax: this.fn.bounds.xMax,
        yMin: this.fn.bounds.yMin,
        yMax: this.fn.bounds.yMax
      };
      rect = this.getDOMNode().getBoundingClientRect();
      xScale = (originalBounds.xMax - originalBounds.xMin) / rect.width;
      yScale = (originalBounds.yMax - originalBounds.yMin) / rect.height;
      UI.dragging = {
        cursor: config.cursor.grabbing,
        onMove: (function(_this) {
          return function(e) {
            var dx, dy;
            dx = e.clientX - originalX;
            dy = e.clientY - originalY;
            return _this.fn.bounds = {
              xMin: originalBounds.xMin - dx * xScale,
              xMax: originalBounds.xMax - dx * xScale,
              yMin: originalBounds.yMin + dy * yScale,
              yMax: originalBounds.yMax + dy * yScale
            };
          };
        })(this)
      };
      return util.onceDragConsummated(e, null, (function(_this) {
        return function() {
          return _this.changeSelection();
        };
      })(this));
    },
    handleMouseDown: function(e) {
      if (e.target.closest(".PointControl")) {
        return;
      }
      UI.preventDefault(e);
      return this.startPan(e);
    },
    handleWheel: function(e) {
      var bounds, scale, scaleFactor, x, y, _ref;
      e.preventDefault();
      _ref = this.getLocalMouseCoords(), x = _ref.x, y = _ref.y;
      bounds = this.fn.bounds;
      scaleFactor = 1.1;
      scale = e.deltaY > 0 ? scaleFactor : 1 / scaleFactor;
      return this.fn.bounds = {
        xMin: (bounds.xMin - x) * scale + x,
        xMax: (bounds.xMax - x) * scale + x,
        yMin: (bounds.yMin - y) * scale + y,
        yMax: (bounds.yMax - y) * scale + y
      };
    },
    renderPlot: function(curve, style) {
      var exprString, fnString;
      exprString = curve.getExprString("x");
      fnString = "(function (x) { return " + exprString + "; })";
      return R.PlotCartesianView({
        bounds: this.fn.bounds,
        fnString: fnString,
        style: style
      });
    },
    render: function() {
      return R.div({
        className: "MainPlot",
        onMouseDown: this.handleMouseDown,
        onWheel: this.handleWheel
      }, R.div({
        className: "PlotContainer"
      }, R.GridView({
        bounds: this.fn.bounds
      }), this.fn.childFns.map((function(_this) {
        return function(childFn) {
          return _this.renderPlot(childFn, config.style["default"]);
        };
      })(this)), this.renderPlot(this.fn, config.style.main), UI.selectedChildFn ? this.renderPlot(UI.selectedChildFn, config.style.selected) : void 0, UI.selectedChildFn ? R.ChildFnControlsView({
        childFn: UI.selectedChildFn
      }) : void 0));
    }
  });

  R.create("ChildFnControlsView", {
    propTypes: {
      childFn: C.ChildFn
    },
    snap: function(value) {
      var bounds, container, digitPrecision, largeSpacing, nearestSnap, pixelWidth, precision, rect, smallSpacing, snapTolerance, _ref;
      container = this.getDOMNode().closest(".PlotContainer");
      rect = container.getBoundingClientRect();
      bounds = this.lookup("fn").bounds;
      pixelWidth = (bounds.xMax - bounds.xMin) / rect.width;
      _ref = util.canvas.getSpacing({
        xMin: bounds.xMin,
        xMax: bounds.xMax,
        yMin: bounds.yMin,
        yMax: bounds.yMax,
        width: rect.width,
        height: rect.height
      }), largeSpacing = _ref.largeSpacing, smallSpacing = _ref.smallSpacing;
      snapTolerance = pixelWidth * config.snapTolerance;
      nearestSnap = Math.round(value / largeSpacing) * largeSpacing;
      if (Math.abs(value - nearestSnap) < snapTolerance) {
        value = nearestSnap;
        digitPrecision = Math.floor(Math.log(largeSpacing) / Math.log(10));
        precision = Math.pow(10, digitPrecision);
        return util.floatToString(value, precision);
      }
      digitPrecision = Math.floor(Math.log(pixelWidth) / Math.log(10));
      precision = Math.pow(10, digitPrecision);
      return util.floatToString(value, precision);
    },
    handleTranslateChange: function(x, y) {
      this.childFn.domainTranslate.valueString = this.snap(x);
      return this.childFn.rangeTranslate.valueString = this.snap(y);
    },
    handleScaleChange: function(x, y) {
      this.childFn.domainScale.valueString = this.snap(x - this.childFn.domainTranslate.getValue());
      return this.childFn.rangeScale.valueString = this.snap(y - this.childFn.rangeTranslate.getValue());
    },
    render: function() {
      return R.span({}, R.PointControlView({
        x: this.childFn.domainTranslate.getValue(),
        y: this.childFn.rangeTranslate.getValue(),
        onChange: this.handleTranslateChange
      }), R.PointControlView({
        x: this.childFn.domainTranslate.getValue() + this.childFn.domainScale.getValue(),
        y: this.childFn.rangeTranslate.getValue() + this.childFn.rangeScale.getValue(),
        onChange: this.handleScaleChange
      }));
    }
  });

  R.create("PointControlView", {
    propTypes: {
      x: Number,
      y: Number,
      onChange: Function
    },
    getDefaultProps: function() {
      return {
        onChange: function() {}
      };
    },
    handleMouseDown: function(e) {
      var container, rect;
      UI.preventDefault(e);
      container = this.getDOMNode().closest(".PlotContainer");
      rect = container.getBoundingClientRect();
      return UI.dragging = {
        onMove: (function(_this) {
          return function(e) {
            var bounds, x, y;
            bounds = _this.lookup("fn").bounds;
            x = (e.clientX - rect.left) / rect.width;
            y = (e.clientY - rect.top) / rect.height;
            x = util.lerp(x, 0, 1, bounds.xMin, bounds.xMax);
            y = util.lerp(y, 1, 0, bounds.yMin, bounds.yMax);
            return _this.onChange(x, y);
          };
        })(this)
      };
    },
    style: function() {
      var bounds, left, top;
      bounds = this.lookup("fn").bounds;
      top = util.lerp(this.y, bounds.yMin, bounds.yMax, 100, 0) + "%";
      left = util.lerp(this.x, bounds.xMin, bounds.xMax, 0, 100) + "%";
      return {
        top: top,
        left: left
      };
    },
    render: function() {
      return R.div({
        className: "PointControl",
        style: this.style(),
        onMouseDown: this.handleMouseDown
      });
    }
  });

}).call(this);
}, "view/OutlineView": function(exports, require, module) {(function() {
  R.create("OutlineView", {
    propTypes: {
      compoundFn: C.CompoundFn
    },
    render: function() {
      var nodeViews, recurse;
      nodeViews = [];
      recurse = function(fn, path) {
        var childFn, nodeView, _i, _len, _ref, _ref1, _results;
        nodeView = R.OutlineNodeView({
          fn: fn,
          path: path,
          key: UI.getPathString(path)
        });
        nodeViews.push(nodeView);
        if (UI.isPathExpanded(path)) {
          fn = (_ref = fn.fn) != null ? _ref : fn;
          if (fn instanceof C.CompoundFn) {
            _ref1 = fn.childFns;
            _results = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              childFn = _ref1[_i];
              _results.push(recurse(childFn, path.concat(childFn)));
            }
            return _results;
          }
        }
      };
      recurse(this.compoundFn, []);
      return R.div({
        className: "Outline"
      }, R.table({
        className: "OutlineContainer"
      }, nodeViews));
    }
  });

  R.create("OutlineNodeView", {
    propTypes: {
      fn: C.Fn,
      path: Array
    },
    render: function() {
      var className, indentLevel;
      indentLevel = this.path.length;
      className = R.cx({
        Selected: this.fn === UI.selectedChildFn
      });
      return R.tbody({
        className: className
      }, R.tr({}, R.td({
        className: "OutlineNodeMain",
        rowSpan: 2,
        style: {
          paddingLeft: indentLevel * config.outlineIndent
        }
      }, R.OutlineMainView({
        fn: this.fn,
        path: this.path
      })), R.td({}, this.fn instanceof C.ChildFn ? R.VariableView({
        variable: this.fn.domainTranslate
      }) : void 0), R.td({}, this.fn instanceof C.ChildFn ? R.VariableView({
        variable: this.fn.rangeTranslate
      }) : void 0)), R.tr({}, R.td({}, this.fn instanceof C.ChildFn ? R.VariableView({
        variable: this.fn.domainScale
      }) : void 0), R.td({}, this.fn instanceof C.ChildFn ? R.VariableView({
        variable: this.fn.rangeScale
      }) : void 0)));
    }
  });

  R.create("OutlineMainView", {
    propTypes: {
      fn: C.Fn,
      path: Array
    },
    toggleExpanded: function() {
      var expanded;
      expanded = UI.isPathExpanded(this.path);
      return UI.setPathExpanded(this.path, !expanded);
    },
    render: function() {
      var disclosureClassName, expanded, fn, _ref;
      fn = (_ref = this.fn.fn) != null ? _ref : this.fn;
      expanded = UI.isPathExpanded(this.path);
      disclosureClassName = R.cx({
        DisclosureTriangle: true,
        Expanded: expanded,
        Hidden: fn instanceof C.BuiltInFn
      });
      return R.div({}, R.div({
        className: disclosureClassName,
        onClick: this.toggleExpanded
      }), R.div({
        className: "OutlineMainContent"
      }, R.LabelView({
        fn: fn
      }), fn instanceof C.CompoundFn && expanded ? R.CombinerView({
        compoundFn: fn
      }) : void 0));
    }
  });

  R.create("LabelView", {
    propTypes: {
      fn: C.Fn
    },
    render: function() {
      return R.TextFieldView({
        className: "OutlineNodeLabel",
        value: this.fn.label
      });
    }
  });

  R.create("CombinerView", {
    propTypes: {
      compoundFn: C.CompoundFn
    },
    handleChange: function(e) {
      var value;
      value = e.target.selectedOptions[0].value;
      return this.compoundFn.combiner = value;
    },
    render: function() {
      return R.div({}, R.select({
        value: this.compoundFn.combiner,
        onChange: this.handleChange
      }, R.option({
        value: "sum"
      }, "Add"), R.option({
        value: "product"
      }, "Multiply"), R.option({
        value: "composition"
      }, "Compose")));
    }
  });

}).call(this);
}, "view/R": function(exports, require, module) {(function() {
  var R, desugarPropType, key, value, _ref,
    __hasProp = {}.hasOwnProperty;

  window.R = R = {};

  _ref = React.DOM;
  for (key in _ref) {
    if (!__hasProp.call(_ref, key)) continue;
    value = _ref[key];
    R[key] = value;
  }

  R.cx = React.addons.classSet;

  R.UniversalMixin = {
    ownerView: function() {
      var _ref1;
      return (_ref1 = this._owner) != null ? _ref1 : this.props.__owner__;
    },
    lookup: function(keyName) {
      var _ref1, _ref2;
      return (_ref1 = this[keyName]) != null ? _ref1 : (_ref2 = this.ownerView()) != null ? _ref2.lookup(keyName) : void 0;
    },
    lookupView: function(viewName) {
      var _ref1;
      if (this === viewName || this.viewName() === viewName) {
        return this;
      }
      return (_ref1 = this.ownerView()) != null ? _ref1.lookupView(viewName) : void 0;
    },
    lookupViewWithKey: function(keyName) {
      var _ref1;
      if (this[keyName] != null) {
        return this;
      }
      return (_ref1 = this.ownerView()) != null ? _ref1.lookupViewWithKey(keyName) : void 0;
    },
    setPropsOnSelf: function(nextProps) {
      var propName, propValue, _results;
      _results = [];
      for (propName in nextProps) {
        if (!__hasProp.call(nextProps, propName)) continue;
        propValue = nextProps[propName];
        if (propName === "__owner__") {
          continue;
        }
        _results.push(this[propName] = propValue);
      }
      return _results;
    },
    componentWillMount: function() {
      return this.setPropsOnSelf(this.props);
    },
    componentWillUpdate: function(nextProps) {
      return this.setPropsOnSelf(nextProps);
    },
    componentDidMount: function() {
      var el;
      el = this.getDOMNode();
      return el.dataFor != null ? el.dataFor : el.dataFor = this;
    },
    componentWillUnmount: function() {
      var el;
      el = this.getDOMNode();
      return delete el.dataFor;
    }
  };

  desugarPropType = function(propType, optional) {
    var required;
    if (optional == null) {
      optional = false;
    }
    if (propType.optional) {
      propType = propType.optional;
      required = false;
    } else if (optional) {
      required = false;
    } else {
      required = true;
    }
    if (propType === Number) {
      propType = React.PropTypes.number;
    } else if (propType === String) {
      propType = React.PropTypes.string;
    } else if (propType === Boolean) {
      propType = React.PropTypes.bool;
    } else if (propType === Function) {
      propType = React.PropTypes.func;
    } else if (propType === Array) {
      propType = React.PropTypes.array;
    } else if (propType === Object) {
      propType = React.PropTypes.object;
    } else if (_.isArray(propType)) {
      propType = React.PropTypes.any;
    } else {
      propType = React.PropTypes.instanceOf(propType);
    }
    if (required) {
      propType = propType.isRequired;
    }
    return propType;
  };

  R.create = function(name, opts) {
    var propName, propType, _ref1;
    opts.displayName = name;
    opts.viewName = function() {
      return name;
    };
    if (opts.propTypes == null) {
      opts.propTypes = {};
    }
    _ref1 = opts.propTypes;
    for (propName in _ref1) {
      if (!__hasProp.call(_ref1, propName)) continue;
      propType = _ref1[propName];
      opts.propTypes[propName] = desugarPropType(propType);
    }
    if (opts.mixins == null) {
      opts.mixins = [];
    }
    opts.mixins.unshift(R.UniversalMixin);
    return R[name] = React.createClass(opts);
  };

  require("./ui/TextFieldView");

  require("./AppRootView");

  require("./DefinitionsView");

  require("./MainPlotView");

  require("./OutlineView");

  require("./VariableView");

  require("./plot/CanvasView");

  require("./plot/GridView");

  require("./plot/PlotCartesianView");

}).call(this);
}, "view/VariableView": function(exports, require, module) {(function() {
  R.create("VariableView", {
    propTypes: {
      variable: C.Variable
    },
    handleInput: function(newValue) {
      return this.variable.valueString = newValue;
    },
    render: function() {
      return R.TextFieldView({
        className: "Variable",
        value: this.variable.valueString,
        onInput: this.handleInput
      });
    }
  });

}).call(this);
}, "view/plot/CanvasView": function(exports, require, module) {(function() {
  R.create("CanvasView", {
    propTypes: {
      drawFn: Function
    },
    draw: function() {
      var canvas;
      canvas = this.getDOMNode();
      return this.drawFn(canvas);
    },
    sizeCanvas: function() {
      var canvas, rect;
      canvas = this.getDOMNode();
      rect = canvas.getBoundingClientRect();
      if (canvas.width !== rect.width || canvas.height !== rect.height) {
        canvas.width = rect.width;
        canvas.height = rect.height;
        return true;
      }
      return false;
    },
    handleResize: function() {
      if (this.sizeCanvas()) {
        return this.draw();
      }
    },
    componentDidUpdate: function() {
      return this.draw();
    },
    componentDidMount: function() {
      this.sizeCanvas();
      this.draw();
      return window.addEventListener("resize", this.handleResize);
    },
    componentWillUnmount: function() {
      return window.removeEventListener("resize", this.handleResize);
    },
    render: function() {
      return R.canvas({});
    }
  });

}).call(this);
}, "view/plot/GridView": function(exports, require, module) {(function() {
  R.create("GridView", {
    propTypes: {
      bounds: Object
    },
    drawFn: function(canvas) {
      var ctx, xMax, xMin, yMax, yMin, _ref;
      ctx = canvas.getContext("2d");
      _ref = this.bounds, xMin = _ref.xMin, xMax = _ref.xMax, yMin = _ref.yMin, yMax = _ref.yMax;
      util.canvas.clear(ctx);
      return util.canvas.drawGrid(ctx, {
        xMin: xMin,
        xMax: xMax,
        yMin: yMin,
        yMax: yMax
      });
    },
    shouldComponentUpdate: function(nextProps) {
      return this.bounds !== nextProps.bounds;
    },
    render: function() {
      return R.CanvasView({
        drawFn: this.drawFn
      });
    }
  });

}).call(this);
}, "view/plot/PlotCartesianView": function(exports, require, module) {(function() {
  R.create("PlotCartesianView", {
    propTypes: {
      bounds: Object,
      fnString: String,
      style: Object
    },
    drawFn: function(canvas) {
      var ctx, fn, xMax, xMin, yMax, yMin, _ref;
      ctx = canvas.getContext("2d");
      fn = util.evaluate(this.fnString);
      util.canvas.clear(ctx);
      _ref = this.bounds, xMin = _ref.xMin, xMax = _ref.xMax, yMin = _ref.yMin, yMax = _ref.yMax;
      util.canvas.drawCartesian(ctx, {
        xMin: xMin,
        xMax: xMax,
        yMin: yMin,
        yMax: yMax,
        fn: fn
      });
      util.canvas.setStyle(ctx, this.style);
      return ctx.stroke();
    },
    shouldComponentUpdate: function(nextProps) {
      return this.bounds !== nextProps.bounds || this.fnString !== nextProps.fnString || this.style !== nextProps.style;
    },
    render: function() {
      return R.CanvasView({
        drawFn: this.drawFn,
        ref: "canvas"
      });
    }
  });

}).call(this);
}, "view/ui/TextFieldView": function(exports, require, module) {(function() {
  var findAdjacentHost;

  R.create("TextFieldView", {
    propTypes: {
      value: String,
      className: String,
      onInput: Function,
      onBackSpace: Function,
      onFocus: Function,
      onBlur: Function,
      allowEnter: Boolean
    },
    getDefaultProps: function() {
      return {
        value: "",
        className: "",
        onInput: function(newValue) {},
        onBackSpace: function() {},
        onEnter: function() {},
        onFocus: function() {},
        onBlur: function() {},
        allowEnter: false
      };
    },
    shouldComponentUpdate: function(nextProps) {
      return this._isDirty || nextProps.value !== this.props.value;
    },
    refresh: function() {
      var el;
      el = this.getDOMNode();
      if (el.textContent !== this.value) {
        el.textContent = this.value;
      }
      this._isDirty = false;
      return UI.attemptAutoFocus(this);
    },
    componentDidMount: function() {
      return this.refresh();
    },
    componentDidUpdate: function() {
      return this.refresh();
    },
    handleInput: function() {
      var el, newValue;
      this._isDirty = true;
      el = this.getDOMNode();
      newValue = el.textContent;
      return this.onInput(newValue);
    },
    handleKeyDown: function(e) {
      var host, nextHost, previousHost;
      host = util.selection.getHost();
      if (e.keyCode === 37) {
        if (util.selection.isAtStart()) {
          previousHost = findAdjacentHost(host, -1);
          if (previousHost) {
            e.preventDefault();
            return util.selection.setAtEnd(previousHost);
          }
        }
      } else if (e.keyCode === 39) {
        if (util.selection.isAtEnd()) {
          nextHost = findAdjacentHost(host, 1);
          if (nextHost) {
            e.preventDefault();
            return util.selection.setAtStart(nextHost);
          }
        }
      } else if (e.keyCode === 8) {
        if (util.selection.isAtStart()) {
          e.preventDefault();
          return this.onBackSpace();
        }
      } else if (e.keyCode === 13) {
        if (!this.allowEnter) {
          e.preventDefault();
          return this.onEnter();
        }
      }
    },
    handleFocus: function() {
      return this.onFocus();
    },
    handleBlur: function() {
      return this.onBlur();
    },
    selectAll: function() {
      var el;
      el = this.getDOMNode();
      return util.selection.setAll(el);
    },
    isFocused: function() {
      var el, host;
      el = this.getDOMNode();
      host = util.selection.getHost();
      return el === host;
    },
    render: function() {
      return R.div({
        className: this.className,
        contentEditable: true,
        onInput: this.handleInput,
        onKeyDown: this.handleKeyDown,
        onFocus: this.handleFocus,
        onBlur: this.handleBlur
      });
    }
  });

  findAdjacentHost = function(el, direction) {
    var hosts, index;
    hosts = document.querySelectorAll("[contenteditable]");
    hosts = _.toArray(hosts);
    index = hosts.indexOf(el);
    return hosts[index + direction];
  };

}).call(this);
}});
