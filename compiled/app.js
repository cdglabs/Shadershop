
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
}).call(this)({"Actions": function(exports, require, module) {(function() {
  var Actions, ensureSelectedChildFnsVisible, findParentIndexOf, getExpandedChildFns;

  window.Actions = Actions = {};

  findParentIndexOf = function(childFnTarget) {
    var recurse;
    recurse = function(compoundFn) {
      var childFn, found, index, _i, _len, _ref;
      index = compoundFn.childFns.indexOf(childFnTarget);
      if (index !== -1) {
        return {
          parent: compoundFn,
          index: index
        };
      }
      _ref = compoundFn.childFns;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        childFn = _ref[_i];
        if (childFn.fn instanceof C.CompoundFn) {
          if (found = recurse(childFn.fn)) {
            return found;
          }
        }
      }
      return null;
    };
    return recurse(UI.selectedFn);
  };

  getExpandedChildFns = function() {
    var recurse, result;
    result = [];
    recurse = function(childFns) {
      var childFn, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = childFns.length; _i < _len; _i++) {
        childFn = childFns[_i];
        if (!childFn.visible) {
          continue;
        }
        result.push(childFn);
        if (UI.isChildFnExpanded(childFn) && childFn.fn instanceof C.CompoundFn) {
          _results.push(recurse(childFn.fn.childFns));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    recurse(UI.selectedFn.childFns);
    return result;
  };

  ensureSelectedChildFnsVisible = function() {
    var expandedChildFns;
    expandedChildFns = getExpandedChildFns();
    return UI.selectedChildFns = _.intersection(UI.selectedChildFns, expandedChildFns);
  };

  Actions.addDefinedFn = function() {
    var fn;
    fn = new C.DefinedFn();
    appRoot.fns.push(fn);
    Compiler.setDirty();
    return Actions.selectFn(fn);
  };

  Actions.addChildFn = function(fn) {
    var childFn, index, onlyChild, parent, possibleParent, takesChildren, _ref;
    if (UI.selectedChildFns.length === 1) {
      possibleParent = UI.selectedChildFns[0].fn;
      takesChildren = possibleParent instanceof C.CompoundFn && UI.isChildFnExpanded(UI.selectedChildFns[0]);
      if (takesChildren) {
        parent = possibleParent;
        index = parent.childFns.length;
      } else {
        _ref = findParentIndexOf(UI.selectedChildFns[0]), parent = _ref.parent, index = _ref.index;
        index = index + 1;
      }
    } else {
      if (UI.selectedFn.childFns.length === 1) {
        onlyChild = UI.selectedFn.childFns[0];
        possibleParent = onlyChild.fn;
        takesChildren = possibleParent instanceof C.CompoundFn && UI.isChildFnExpanded(onlyChild);
        if (takesChildren) {
          parent = possibleParent;
          index = parent.childFns.length;
        }
      }
    }
    if (parent == null) {
      parent = UI.selectedFn;
      index = parent.childFns.length;
    }
    childFn = new C.ChildFn(fn);
    Actions.insertChildFn(parent, childFn, index);
    Actions.selectChildFn(childFn);
    return {
      childFn: childFn,
      parent: parent,
      index: index
    };
  };

  Actions.addCompoundFn = function(combiner) {
    var childFn, childFnInfo, childFnInfos, commonParent, compoundFn, compoundFnContainer, index, parent, _i, _j, _len, _len1, _ref, _ref1;
    if (combiner == null) {
      combiner = "sum";
    }
    compoundFn = new C.CompoundFn();
    compoundFn.combiner = combiner;
    compoundFnContainer = new C.ChildFn(compoundFn);
    childFnInfos = [];
    _ref = UI.selectedChildFns;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      childFn = _ref[_i];
      _ref1 = findParentIndexOf(childFn), parent = _ref1.parent, index = _ref1.index;
      childFnInfos.push({
        parent: parent,
        index: index,
        childFn: childFn
      });
    }
    if (childFnInfos.length > 0) {
      commonParent = childFnInfos[0].parent;
      if (_.all(childFnInfos, function(childFnInfo) {
        return childFnInfo.parent === commonParent;
      })) {
        childFnInfos = _.sortBy(childFnInfos, "index");
        for (_j = 0, _len1 = childFnInfos.length; _j < _len1; _j++) {
          childFnInfo = childFnInfos[_j];
          Actions.removeChildFn(commonParent, childFnInfo.childFn);
          compoundFn.childFns.push(childFnInfo.childFn);
        }
        index = childFnInfos[0].index;
        commonParent.childFns.splice(index, 0, compoundFnContainer);
        Actions.selectChildFn(compoundFnContainer);
        return;
      }
    }
    compoundFn.childFns = UI.selectedFn.childFns;
    UI.selectedFn.childFns = [compoundFnContainer];
    Actions.selectChildFn(compoundFnContainer);
    return Compiler.setDirty();
  };

  Actions.removeChildFn = function(parentCompoundFn, childFn) {
    var index;
    index = parentCompoundFn.childFns.indexOf(childFn);
    if (index === -1) {
      return;
    }
    parentCompoundFn.childFns.splice(index, 1);
    ensureSelectedChildFnsVisible();
    return Compiler.setDirty();
  };

  Actions.insertChildFn = function(parentCompoundFn, childFn, index) {
    parentCompoundFn.childFns.splice(index, 0, childFn);
    return Compiler.setDirty();
  };

  Actions.setFnLabel = function(fn, newValue) {
    return fn.label = newValue;
  };

  Actions.setCompoundFnCombiner = function(compoundFn, combiner) {
    compoundFn.combiner = combiner;
    return Compiler.setDirty();
  };

  Actions.setVariableValueString = function(variable, newValueString) {
    variable.valueString = newValueString;
    return Compiler.setDirty();
  };

  Actions.toggleChildFnVisible = function(childFn) {
    return Actions.setChildFnVisible(childFn, !childFn.visible);
  };

  Actions.setChildFnVisible = function(childFn, newVisible) {
    childFn.visible = newVisible;
    ensureSelectedChildFnsVisible();
    return Compiler.setDirty();
  };

  Actions.setBasisVector = function(childFn, space, coord, valueStrings) {
    childFn.setBasisVector(space, coord, valueStrings);
    return Compiler.setDirty();
  };

  Actions.panPlot = function(plot, from, to) {
    var offset;
    offset = numeric.sub(from, to);
    return plot.center = numeric.add(plot.center, offset);
  };

  Actions.zoomPlot = function(plot, zoomCenter, scaleFactor) {
    var offset;
    offset = numeric.sub(plot.center, zoomCenter);
    plot.center = numeric.add(zoomCenter, numeric.mul(offset, scaleFactor));
    return plot.pixelSize *= scaleFactor;
  };

  Actions.panPlotLayout = function(plotLayout, from, to) {
    var plot, _i, _len, _ref, _results;
    _ref = plotLayout.plots;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      plot = _ref[_i];
      _results.push(Actions.panPlot(plot, from, to));
    }
    return _results;
  };

  Actions.zoomPlotLayout = function(plotLayout, zoomCenter, scaleFactor) {
    var plot, _i, _len, _ref, _results;
    _ref = plotLayout.plots;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      plot = _ref[_i];
      _results.push(Actions.zoomPlot(plot, zoomCenter, scaleFactor));
    }
    return _results;
  };

  Actions.setPlotLayoutFocus = function(plotLayout, focus) {
    var plot, _i, _len, _ref, _results;
    _ref = plotLayout.plots;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      plot = _ref[_i];
      _results.push(plot.focus = focus);
    }
    return _results;
  };

  Actions.selectFn = function(fn) {
    if (!(fn instanceof C.DefinedFn)) {
      return;
    }
    UI.selectedFn = fn;
    UI.selectedChildFns = [];
    return Compiler.setDirty();
  };

  Actions.selectChildFn = function(childFn) {
    if (childFn === null) {
      UI.selectedChildFns = [];
    } else {
      UI.selectedChildFns = [childFn];
    }
    ensureSelectedChildFnsVisible();
    return Compiler.setDirty();
  };

  Actions.toggleSelectChildFn = function(childFn) {
    if (_.contains(UI.selectedChildFns, childFn)) {
      UI.selectedChildFns = _.without(UI.selectedChildFns, childFn);
    } else {
      UI.selectedChildFns.push(childFn);
    }
    ensureSelectedChildFnsVisible();
    return Compiler.setDirty();
  };

  Actions.hoverChildFn = function(childFn) {
    return UI.hoveredChildFn = childFn;
  };

  Actions.toggleChildFnExpanded = function(childFn) {
    var expanded;
    expanded = UI.isChildFnExpanded(childFn);
    return Actions.setChildFnExpanded(childFn, !expanded);
  };

  Actions.setChildFnExpanded = function(childFn, expanded) {
    var id;
    id = C.id(childFn);
    UI.expandedChildFns[id] = expanded;
    return ensureSelectedChildFnsVisible();
  };

}).call(this);
}, "Compiler": function(exports, require, module) {
/*

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
 */

(function() {
  var Compiler, cache, getAllDependencies, getDependencies, getExprStringAndDependencies, getGlslFnString, identityMatrixString, vecType, zeroVectorString;

  window.Compiler = Compiler = {};

  vecType = util.glslVectorType(config.dimensions);

  zeroVectorString = util.glslString(util.constructVector(config.dimensions, 0));

  identityMatrixString = util.glslString(numeric.identity(config.dimensions));

  cache = {};

  Compiler.setDirty = function() {
    return cache = {};
  };

  getExprStringAndDependencies = function(fn) {
    var dependencies, exprString, id, recurse, result;
    id = C.id(fn);
    if (cache[id] != null) {
      return cache[id];
    }
    dependencies = [];
    recurse = function(fn, parameter, firstCall) {
      var childExprStrings, childFn, domainTransformInv, domainTranslate, exprString, rangeTransform, rangeTranslate, visibleChildFns, _i, _len;
      if (firstCall == null) {
        firstCall = false;
      }
      if (fn instanceof C.BuiltInFn) {
        if (fn.fnName === "identity") {
          return parameter;
        }
        return "" + fn.fnName + "(" + parameter + ")";
      }
      if (fn instanceof C.DefinedFn && !firstCall) {
        dependencies.push(fn);
        return "" + (C.id(fn)) + "(" + parameter + ")";
      }
      if (fn instanceof C.CompoundFn) {
        visibleChildFns = _.filter(fn.childFns, function(childFn) {
          return childFn.visible;
        });
        if (fn.combiner === "last") {
          if (visibleChildFns.length > 0) {
            return recurse(_.last(visibleChildFns), parameter);
          } else {
            return util.glslString(util.constructVector(config.dimensions, 0));
          }
        }
        if (fn.combiner === "composition") {
          exprString = parameter;
          for (_i = 0, _len = visibleChildFns.length; _i < _len; _i++) {
            childFn = visibleChildFns[_i];
            exprString = recurse(childFn, exprString);
          }
          return exprString;
        }
        childExprStrings = visibleChildFns.map((function(_this) {
          return function(childFn) {
            return recurse(childFn, parameter);
          };
        })(this));
        if (fn.combiner === "sum") {
          if (childExprStrings.length === 0) {
            return util.glslString(util.constructVector(config.dimensions, 0));
          } else {
            return "(" + childExprStrings.join(" + ") + ")";
          }
        }
        if (fn.combiner === "product") {
          if (childExprStrings.length === 0) {
            return util.glslString(util.constructVector(config.dimensions, 1));
          } else {
            return "(" + childExprStrings.join(" * ") + ")";
          }
        }
      }
      if (fn instanceof C.ChildFn) {
        if (fn === UI.getSingleSelectedChildFn()) {
          exprString = parameter;
          exprString = "selectedDomainTransformInv * (" + exprString + " - selectedDomainTranslate)";
          exprString = recurse(fn.fn, exprString);
          exprString = "((selectedRangeTransform * " + exprString + ") + selectedRangeTranslate)";
          return exprString;
        }
        domainTranslate = util.glslString(fn.getDomainTranslate());
        domainTransformInv = util.glslString(util.safeInv(fn.getDomainTransform()));
        rangeTranslate = util.glslString(fn.getRangeTranslate());
        rangeTransform = util.glslString(fn.getRangeTransform());
        exprString = parameter;
        if (domainTranslate !== zeroVectorString) {
          exprString = "(" + exprString + " - " + domainTranslate + ")";
        }
        if (domainTransformInv !== identityMatrixString) {
          exprString = "(" + domainTransformInv + " * " + exprString + ")";
        }
        exprString = recurse(fn.fn, exprString);
        if (rangeTransform !== identityMatrixString) {
          exprString = "(" + rangeTransform + " * " + exprString + ")";
        }
        if (rangeTranslate !== zeroVectorString) {
          exprString = "(" + exprString + " + " + rangeTranslate + ")";
        }
        return exprString;
      }
    };
    exprString = recurse(fn, "inputVal", true);
    result = {
      exprString: exprString,
      dependencies: dependencies
    };
    cache[id] = result;
    return result;
  };

  getDependencies = function(fn) {
    return getExprStringAndDependencies(fn).dependencies;
  };

  getAllDependencies = function(fn) {
    var allDependencies, recurse;
    allDependencies = [];
    recurse = function(fn) {
      var dependencies, dependency, _i, _len, _results;
      dependencies = getDependencies(fn);
      allDependencies = allDependencies.concat(dependencies);
      _results = [];
      for (_i = 0, _len = dependencies.length; _i < _len; _i++) {
        dependency = dependencies[_i];
        _results.push(recurse(dependency));
      }
      return _results;
    };
    recurse(fn);
    allDependencies.reverse();
    allDependencies = _.unique(allDependencies);
    return allDependencies;
  };

  getGlslFnString = function(fn, name) {
    var exprString;
    if (name == null) {
      name = C.id(fn);
    }
    exprString = getExprStringAndDependencies(fn).exprString;
    return "" + vecType + " " + name + "(" + vecType + " inputVal) {return " + exprString + ";}";
  };

  Compiler.getGlsl = function(fn) {
    var allDependencies, dependency, exprString, fnStrings;
    exprString = getExprStringAndDependencies(fn).exprString;
    allDependencies = getAllDependencies(fn);
    fnStrings = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = allDependencies.length; _i < _len; _i++) {
        dependency = allDependencies[_i];
        _results.push(getGlslFnString(dependency));
      }
      return _results;
    })();
    fnStrings.push(getGlslFnString(fn, "mainFn"));
    return fnStrings.join("\n");
  };

}).call(this);
}, "UI": function(exports, require, module) {(function() {
  var UI,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.UI = UI = new ((function() {
    function _Class() {
      this.handleWindowMouseUp = __bind(this.handleWindowMouseUp, this);
      this.handleWindowMouseMove = __bind(this.handleWindowMouseMove, this);
      this.dragging = null;
      this.mousePosition = {
        x: 0,
        y: 0
      };
      this.autofocus = null;
      this.selectedFn = _.last(appRoot.fns);
      this.selectedChildFns = [];
      this.hoveredChildFn = null;
      this.expandedChildFns = {};
      this.showSymbolic = false;
      this.registerEvents();
    }

    _Class.prototype.registerEvents = function() {
      window.addEventListener("mousemove", this.handleWindowMouseMove);
      return window.addEventListener("mouseup", this.handleWindowMouseUp);
    };

    _Class.prototype.isChildFnExpanded = function(childFn) {
      var expanded, id;
      id = C.id(childFn);
      expanded = this.expandedChildFns[id];
      if (expanded == null) {
        if (childFn.fn instanceof C.DefinedFn) {
          return false;
        } else {
          return true;
        }
      }
      return expanded;
    };

    _Class.prototype.getSingleSelectedChildFn = function() {
      if (this.selectedChildFns.length === 1) {
        return this.selectedChildFns[0];
      } else {
        return null;
      }
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

    return _Class;

  })());

}).call(this);
}, "config": function(exports, require, module) {(function() {
  var childColor, config, hoveredColor, mainColor, mixColors, selectedColor;

  mixColors = function(c1, c2, amount) {
    var amount1, amount2;
    amount1 = 1 - amount;
    amount2 = amount;
    return numeric.add(numeric.mul(amount1, c1), numeric.mul(amount2, c2));
  };

  mainColor = [0.2, 0.2, 0.2, 1];

  childColor = [0.8, 0.8, 0.8, 1];

  selectedColor = [0, 0.6, 0.8, 1];

  hoveredColor = mixColors(childColor, selectedColor, 0.3);

  window.config = config = {
    storageName: "sinewaves",
    resolution: 0.5,
    dimensions: 4,
    mainLineWidth: 1.25,
    minGridSpacing: 90,
    hitTolerance: 10,
    snapTolerance: 7,
    outlineIndent: 16,
    gridColor: "204,194,163",
    domainLabelColor: "#900",
    rangeLabelColor: "#090",
    colorMapZero: util.hslToRgb(0, 0, 0).map(util.glslString).join(","),
    colorMapPositive: util.hslToRgb(0, 0, 1).map(util.glslString).join(","),
    colorMapNegative: util.hslToRgb(226, 1, 0.4).map(util.glslString).join(","),
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
    color: {
      main: mainColor,
      child: childColor,
      selected: selectedColor,
      hovered: hoveredColor
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
  var debouncedSaveState, eventName, json, refresh, refreshEventNames, refreshView, saveState, storageName, willRefreshNextFrame, _i, _len;

  require("./util/util");

  require("./config");

  require("./model/C");

  require("./Actions");

  require("./Compiler");

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

  debouncedSaveState = _.debounce(saveState, 400);

  willRefreshNextFrame = false;

  refresh = function() {
    if (willRefreshNextFrame) {
      return;
    }
    willRefreshNextFrame = true;
    return requestAnimationFrame(function() {
      refreshView();
      debouncedSaveState();
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

  if (location.protocol === "file:" && navigator.userAgent.indexOf("Firefox") === -1 && location.href.indexOf("dev.html") !== -1) {
    setInterval(function() {
      return document.styleSheets[0].reload();
    }, 1000);
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
      this.valueString = this.valueString.toString();
      this._lastValueString = null;
      this._lastWorkingValue = null;
      this.getValue();
    }

    Variable.prototype.getValue = function() {
      var value;
      if (this.valueString === this._lastValueString) {
        return this._lastWorkingValue;
      }
      value = this._lastWorkingValue;
      try {
        if (/^[-+]?[0-9]*\.?[0-9]+$/.test(this.valueString)) {
          value = parseFloat(this.valueString);
        } else {
          value = util.evaluate(this.valueString);
        }
      } catch (_error) {}
      if (!_.isFinite(value)) {
        value = this._lastWorkingValue;
      }
      this._lastWorkingValue = value;
      this._lastValueString = this.valueString;
      return value;
    };

    Variable.prototype.duplicate = function() {
      return new C.Variable(this.valueString);
    };

    return Variable;

  })();

  C.Fn = (function() {
    function Fn() {}

    Fn.prototype.evaluate = function(x) {
      throw "Not implemented";
    };

    return Fn;

  })();

  C.BuiltInFn = (function(_super) {
    __extends(BuiltInFn, _super);

    function BuiltInFn(fnName, label) {
      this.fnName = fnName;
      this.label = label;
    }

    BuiltInFn.prototype.evaluate = function(x) {
      return builtIn.fnEvaluators[this.fnName](x);
    };

    BuiltInFn.prototype.duplicate = function() {
      return this;
    };

    return BuiltInFn;

  })(C.Fn);

  C.CompoundFn = (function(_super) {
    __extends(CompoundFn, _super);

    function CompoundFn() {
      this.combiner = "sum";
      this.childFns = [];
    }

    CompoundFn.prototype.evaluate = function(x) {
      var childFn, reducer, _i, _len, _ref;
      if (this.combiner === "last") {
        if (this.childFns.length > 0) {
          return _.last(this.childFns).evaluate(x);
        } else {
          return util.constructVector(config.dimensions, 0);
        }
      }
      if (this.combiner === "composition") {
        _ref = this.childFns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childFn = _ref[_i];
          x = childFn.evaluate(x);
        }
        return x;
      }
      if (this.combiner === "sum") {
        reducer = function(result, childFn) {
          return numeric.add(result, childFn.evaluate(x));
        };
        return _.reduce(this.childFns, reducer, util.constructVector(config.dimensions, 0));
      }
      if (this.combiner === "product") {
        reducer = function(result, childFn) {
          return numeric.mul(result, childFn.evaluate(x));
        };
        return _.reduce(this.childFns, reducer, util.constructVector(config.dimensions, 1));
      }
    };

    CompoundFn.prototype.duplicate = function() {
      var compoundFn;
      compoundFn = new C.CompoundFn();
      compoundFn.combiner = this.combiner;
      compoundFn.childFns = this.childFns.map(function(childFn) {
        return childFn.duplicate();
      });
      return compoundFn;
    };

    return CompoundFn;

  })(C.Fn);

  C.DefinedFn = (function(_super) {
    __extends(DefinedFn, _super);

    function DefinedFn() {
      DefinedFn.__super__.constructor.call(this);
      this.combiner = "last";
      this.plotLayout = new C.PlotLayout();
    }

    DefinedFn.prototype.duplicate = function() {
      return this;
    };

    return DefinedFn;

  })(C.CompoundFn);

  C.ChildFn = (function(_super) {
    __extends(ChildFn, _super);

    function ChildFn(fn) {
      this.fn = fn;
      this.visible = true;
      this.domainTranslate = util.constructVector(config.dimensions, 0).map(function(v) {
        return new C.Variable(v);
      });
      this.domainTransform = numeric.identity(config.dimensions).map(function(row) {
        return row.map(function(v) {
          return new C.Variable(v);
        });
      });
      this.rangeTranslate = util.constructVector(config.dimensions, 0).map(function(v) {
        return new C.Variable(v);
      });
      this.rangeTransform = numeric.identity(config.dimensions).map(function(row) {
        return row.map(function(v) {
          return new C.Variable(v);
        });
      });
    }

    ChildFn.prototype.getDomainTranslate = function() {
      return this.domainTranslate.map(function(v) {
        return v.getValue();
      });
    };

    ChildFn.prototype.getDomainTransform = function() {
      return this.domainTransform.map(function(row) {
        return row.map(function(v) {
          return v.getValue();
        });
      });
    };

    ChildFn.prototype.getRangeTranslate = function() {
      return this.rangeTranslate.map(function(v) {
        return v.getValue();
      });
    };

    ChildFn.prototype.getRangeTransform = function() {
      return this.rangeTransform.map(function(row) {
        return row.map(function(v) {
          return v.getValue();
        });
      });
    };

    ChildFn.prototype.getBasisVector = function(space, coord) {
      var matrix, row, vector, _i, _ref;
      matrix = (space === "domain" ? this.domainTransform : this.rangeTransform);
      vector = [];
      for (row = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; row = 0 <= _ref ? ++_i : --_i) {
        vector.push(matrix[row][coord].getValue());
      }
      return vector;
    };

    ChildFn.prototype.setBasisVector = function(space, coord, valueStrings) {
      var matrix, row, _i, _ref, _results;
      matrix = (space === "domain" ? this.domainTransform : this.rangeTransform);
      _results = [];
      for (row = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; row = 0 <= _ref ? ++_i : --_i) {
        _results.push(matrix[row][coord].valueString = valueStrings[row]);
      }
      return _results;
    };

    ChildFn.prototype.evaluate = function(x) {
      var domainTransformInv, domainTranslate, rangeTransform, rangeTranslate;
      domainTranslate = this.getDomainTranslate();
      domainTransformInv = util.safeInv(this.getDomainTransform());
      rangeTranslate = this.getRangeTranslate();
      rangeTransform = this.getRangeTransform();
      x = numeric.dot(domainTransformInv, numeric.sub(x, domainTranslate));
      x = this.fn.evaluate(x);
      x = numeric.add(numeric.dot(rangeTransform, x), rangeTranslate);
      return x;
    };

    ChildFn.prototype.duplicate = function() {
      var childFn;
      childFn = new C.ChildFn(this.fn.duplicate());
      childFn.visible = this.visible;
      childFn.domainTranslate = this.domainTranslate.map(function(variable) {
        return variable.duplicate();
      });
      childFn.domainTransform = this.domainTransform.map(function(row) {
        return row.map(function(variable) {
          return variable.duplicate();
        });
      });
      childFn.rangeTranslate = this.rangeTranslate.map(function(variable) {
        return variable.duplicate();
      });
      childFn.rangeTransform = this.rangeTransform.map(function(row) {
        return row.map(function(variable) {
          return variable.duplicate();
        });
      });
      return childFn;
    };

    return ChildFn;

  })(C.Fn);

  C.PlotLayout = (function() {
    function PlotLayout() {
      this.plots = [new C.Plot(), new C.Plot(), new C.Plot()];
      this.display2d = false;
    }

    PlotLayout.prototype.getMainPlot = function() {
      return this.plots[0];
    };

    PlotLayout.prototype.getPlotLocations = function() {
      if (this.display2d) {
        return [
          {
            plot: this.plots[0],
            x: 0,
            y: 0.3,
            w: 0.7,
            h: 0.7
          }, {
            plot: this.plots[1],
            x: 0,
            y: 0,
            w: 0.7,
            h: 0.3
          }, {
            plot: this.plots[2],
            x: 0.7,
            y: 0.3,
            w: 0.3,
            h: 0.7
          }
        ];
      } else {
        return [
          {
            plot: this.plots[0],
            x: 0,
            y: 0,
            w: 1,
            h: 1
          }
        ];
      }
    };

    return PlotLayout;

  })();

  C.Plot = (function() {
    function Plot() {
      this.center = util.constructVector(config.dimensions * 2, 0);
      this.focus = util.constructVector(config.dimensions * 2, 0);
      this.pixelSize = .01;
      this.type = "cartesian";
    }

    Plot.prototype.getDimensionsOld = function() {
      if (this.type === "cartesian") {
        return [
          {
            space: "domain",
            coord: 0
          }, {
            space: "range",
            coord: 0
          }
        ];
      } else if (this.type === "cartesian2") {
        return [
          {
            space: "range",
            coord: 0
          }, {
            space: "domain",
            coord: 1
          }
        ];
      } else if (this.type === "colorMap") {
        return [
          {
            space: "domain",
            coord: 0
          }, {
            space: "domain",
            coord: 1
          }
        ];
      }
    };

    Plot.prototype.getScaledBounds = function(width, height, scaleFactor) {
      var center, dimensions, pixelSize, xPixelCenter, yPixelCenter;
      pixelSize = this.pixelSize;
      center = {
        domain: this.center.slice(0, this.center.length / 2),
        range: this.center.slice(this.center.length / 2)
      };
      dimensions = this.getDimensionsOld();
      xPixelCenter = center[dimensions[0].space][dimensions[0].coord];
      yPixelCenter = center[dimensions[1].space][dimensions[1].coord];
      return {
        xMin: xPixelCenter - pixelSize * (width / 2) * scaleFactor,
        xMax: xPixelCenter + pixelSize * (width / 2) * scaleFactor,
        yMin: yPixelCenter - pixelSize * (height / 2) * scaleFactor,
        yMax: yPixelCenter + pixelSize * (height / 2) * scaleFactor
      };
    };

    Plot.prototype.getPixelSize = function() {
      return this.pixelSize;
    };

    Plot.prototype.getDimensions = function() {
      if (this.type === "cartesian") {
        return [[1, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 1, 0, 0, 0]];
      } else if (this.type === "cartesian2") {
        return [[0, 0, 0, 0, 1, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0]];
      } else if (this.type === "colorMap") {
        return [[1, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0]];
      }
    };

    Plot.prototype.getMask = function() {
      var dimension, dimensions, mask, _i, _len;
      dimensions = this.getDimensions();
      mask = util.constructVector(config.dimensions * 2, 0);
      for (_i = 0, _len = dimensions.length; _i < _len; _i++) {
        dimension = dimensions[_i];
        mask = numeric.add(dimension, mask);
      }
      return mask;
    };

    Plot.prototype.getCombinedCenter = function() {
      return util.vectorMask(this.center, this.focus, this.getMask());
    };

    Plot.prototype.toWorld = function(_arg) {
      var offset, pixelSize, x, y;
      x = _arg.x, y = _arg.y;
      pixelSize = this.getPixelSize();
      offset = numeric.dot(numeric.mul([x, y], pixelSize), this.getDimensions());
      return numeric.add(offset, this.getCombinedCenter());
    };

    Plot.prototype.toPixel = function(worldPoint) {
      var offset, pixelSize, xyPoint;
      pixelSize = this.getPixelSize();
      offset = numeric.sub(worldPoint, this.getCombinedCenter());
      xyPoint = numeric.div(numeric.dot(this.getDimensions(), offset), pixelSize);
      return {
        x: xyPoint[0],
        y: xyPoint[1]
      };
    };

    return Plot;

  })();

  C.AppRoot = (function() {
    function AppRoot() {
      this.fns = [new C.DefinedFn()];
    }

    return AppRoot;

  })();

  window.builtIn = builtIn = {};

  builtIn.fns = [new C.BuiltInFn("identity", "Line"), new C.BuiltInFn("abs", "Abs"), new C.BuiltInFn("fract", "Fract"), new C.BuiltInFn("floor", "Floor"), new C.BuiltInFn("sin", "Sine")];

  builtIn.fnEvaluators = {
    identity: function(x) {
      return x;
    },
    abs: numeric.abs,
    fract: function(x) {
      return numeric.sub(x, numeric.floor(x));
    },
    floor: numeric.floor,
    sin: numeric.sin
  };

  builtIn.defaultPlotLayout = new C.PlotLayout();

}).call(this);
}, "util/canvas": function(exports, require, module) {(function() {
  var canvasBounds, clear, drawGrid, drawLine, getSpacing, lerp, ticks;

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

  getSpacing = function(pixelSize) {
    var div, largeSpacing, minSpacing, smallSpacing, z;
    minSpacing = pixelSize * config.minGridSpacing;

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
    var axesColor, axesOpacity, color, cx, cxMax, cxMin, cy, cyMax, cyMin, fromLocal, height, labelColor, labelDistance, labelEdgeDistance, labelOpacity, largeSpacing, majorColor, majorOpacity, minorColor, minorOpacity, originX, originY, pixelSize, smallSpacing, text, textHeight, toLocal, width, x, xLabel, xLabelColor, xMax, xMin, y, yLabel, yLabelColor, yMax, yMin, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _ref, _ref1, _ref10, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    xMin = opts.xMin;
    xMax = opts.xMax;
    yMin = opts.yMin;
    yMax = opts.yMax;
    pixelSize = opts.pixelSize;
    xLabel = opts.xLabel;
    yLabel = opts.yLabel;
    xLabelColor = opts.xLabelColor;
    yLabelColor = opts.yLabelColor;
    _ref = canvasBounds(ctx), cxMin = _ref.cxMin, cxMax = _ref.cxMax, cyMin = _ref.cyMin, cyMax = _ref.cyMax, width = _ref.width, height = _ref.height;
    _ref1 = getSpacing(pixelSize), largeSpacing = _ref1.largeSpacing, smallSpacing = _ref1.smallSpacing;
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
    labelEdgeDistance = labelDistance * 6;
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
        if (cx < cxMax - labelEdgeDistance) {
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
    }
    ctx.textAlign = "left";
    ctx.textBaseline = "middle";
    _ref8 = ticks(largeSpacing, yMin, yMax);
    for (_n = 0, _len5 = _ref8.length; _n < _len5; _n++) {
      y = _ref8[_n];
      if (y !== 0) {
        text = parseFloat(y.toPrecision(12)).toString();
        _ref9 = fromLocal([0, y]), cx = _ref9[0], cy = _ref9[1];
        if (cy > labelEdgeDistance) {
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
    }
    if (xLabel) {
      _ref10 = fromLocal([0, 0]), originX = _ref10[0], originY = _ref10[1];
      text = xLabel;
      ctx.fillStyle = xLabelColor;
      cx = cxMax - labelDistance;
      cy = originY + labelDistance;
      if (cy < labelDistance) {
        cy = labelDistance;
      }
      if (cy + textHeight + labelDistance > height) {
        cy = height - labelDistance - textHeight;
      }
      ctx.textAlign = "right";
      ctx.textBaseline = "top";
      ctx.fillText(text, cx, cy);
      text = yLabel;
      ctx.fillStyle = yLabelColor;
      cx = originX + labelDistance;
      cy = labelDistance;
      if (cx < labelDistance) {
        cx = labelDistance;
      }
      if (cx + ctx.measureText(text).width + labelDistance > width) {
        cx = width - labelDistance - ctx.measureText(text).width;
      }
      ctx.textAlign = "left";
      ctx.textBaseline = "top";
      ctx.fillText(text, cx, cy);
    }
    return ctx.restore();
  };

  util.canvas = {
    lerp: lerp,
    clear: clear,
    getSpacing: getSpacing,
    drawGrid: drawGrid
  };

}).call(this);
}, "util/evaluate": function(exports, require, module) {(function() {
  var PI, TAU, abs, add, ceil, cos, div, evaluate, evaluateFn, floor, fract, identity, max, min, mul, pow, sin, sqrt, sub;

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

  PI = Math.PI;

  TAU = Math.PI * 2;

  util.evaluate = evaluate;

  util.evaluateFn = evaluateFn;

}).call(this);
}, "util/numeric": function(exports, require, module) {(function() {
  var normalize, num, reflectionMatrix, rotationMatrix, rotationScalingMatrix;

  num = numeric;

  normalize = function(a) {
    return num.div(a, num.norm2(a));
  };

  reflectionMatrix = function(n) {
    var I;
    I = num.identity(n.length);
    return num.sub(I, num.mul(2, num.dot(num.transpose([n]), [n])));
  };

  rotationMatrix = function(a, b) {
    var Rb, Rn, n;
    n = normalize(num.add(a, b));
    Rn = reflectionMatrix(n);
    Rb = reflectionMatrix(b);
    return num.dot(Rb, Rn);
  };

  rotationScalingMatrix = function(a, b) {
    var I, R, S, aUnit, bUnit, scaleFactor;
    aUnit = normalize(a);
    bUnit = normalize(b);
    scaleFactor = num.norm2(b) / num.norm2(a);
    I = num.identity(a.length);
    S = num.mul(scaleFactor, I);
    R = rotationMatrix(aUnit, bUnit);
    return num.dot(S, R);
  };

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

  Element.prototype.getClippingRect = function() {
    var el, rect, scrollerRect;
    rect = this.getBoundingClientRect();
    rect = {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom
    };
    el = this.parentNode;
    while ((el != null ? el.nodeType : void 0) === Node.ELEMENT_NODE) {
      if (el.matches(".Scroller")) {
        scrollerRect = el.getBoundingClientRect();
        rect.left = Math.max(rect.left, scrollerRect.left);
        rect.right = Math.min(rect.right, scrollerRect.right);
        rect.top = Math.max(rect.top, scrollerRect.top);
        rect.bottom = Math.min(rect.bottom, scrollerRect.bottom);
      }
      el = el.parentNode;
    }
    rect.width = rect.right - rect.left;
    rect.height = rect.bottom - rect.top;
    return rect;
  };

  util.preventDefault = function(e) {
    e.preventDefault();
    return util.selection.set(null);
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

  util.glslString = function(value) {
    var col, component, index, length, row, string, strings, _i, _j, _k, _len;
    if (value === 0) {
      return "0.";
    }
    if (value === 1) {
      return "1.";
    }
    if (_.isNumber(value)) {
      string = value.toString();
      if (!/\./.test(string)) {
        string = string + ".";
      }
      return string;
    }
    if (_.isArray(value) && _.isNumber(value[0])) {
      length = value.length;
      if (length === 1) {
        return util.glslString(value[0]);
      }
      string = "";
      for (index = _i = 0, _len = value.length; _i < _len; index = ++_i) {
        component = value[index];
        string += util.glslString(component);
        if (index < length - 1) {
          string += ",";
        }
      }
      string = util.glslVectorType(length) + "(" + string + ")";
      return string;
    }
    if (_.isArray(value) && _.isArray(value[0])) {
      length = value.length;
      if (length === 1) {
        return util.glslString(value[0][0]);
      }
      strings = [];
      string = "";
      for (col = _j = 0; 0 <= length ? _j < length : _j > length; col = 0 <= length ? ++_j : --_j) {
        for (row = _k = 0; 0 <= length ? _k < length : _k > length; row = 0 <= length ? ++_k : --_k) {
          string += util.glslString(value[row][col]);
          if (row < length - 1 || col < length - 1) {
            string += ",";
          }
        }
      }
      string = util.glslMatrixType(length) + "(" + string + ")";
      return string;
    }
  };

  util.glslMatrixArray = function(matrix) {
    var col, length, result, row, _i, _j;
    result = [];
    length = matrix.length;
    for (col = _i = 0; 0 <= length ? _i < length : _i > length; col = 0 <= length ? ++_i : --_i) {
      for (row = _j = 0; 0 <= length ? _j < length : _j > length; row = 0 <= length ? ++_j : --_j) {
        result.push(matrix[row][col]);
      }
    }
    return result;
  };

  util.glslVectorType = function(dimensions) {
    if (dimensions === 1) {
      return "float";
    }
    return "vec" + dimensions;
  };

  util.glslMatrixType = function(dimensions) {
    if (dimensions === 1) {
      return "float";
    }
    return "mat" + dimensions;
  };

  util.glslGetComponent = function(expr, dimensions, component) {
    if (dimensions === 1) {
      return expr;
    }
    return expr + "[" + component + "]";
  };

  util.glslSetComponent = function(expr, dimensions, component, value) {
    if (dimensions === 1) {
      return expr + " = " + value;
    }
    return expr + "[" + component + "]" + " = " + value;
  };

  util.constructVector = function(dimensions, value) {
    var _i, _results;
    return (function() {
      _results = [];
      for (var _i = 0; 0 <= dimensions ? _i < dimensions : _i > dimensions; 0 <= dimensions ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).map(function() {
      return value;
    });
  };

  util.safeInv = function(m) {
    if (m.length === 1 && m[0][0] === 0) {
      return numeric.identity(1);
    }
    try {
      return numeric.inv(m);
    } catch (_error) {
      return numeric.identity(m.length);
    }
  };

  util.vectorMask = function(a, b, mask) {
    return numeric.add(numeric.mul(a, mask), numeric.mul(b, numeric.sub(1, mask)));
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

  
function RGBToHSL(r, g, b) {
  var
  min = Math.min(r, g, b),
  max = Math.max(r, g, b),
  diff = max - min,
  h = 0, s = 0, l = (min + max) / 2;

  if (diff != 0) {
    s = l < 0.5 ? diff / (max + min) : diff / (2 - max - min);

    h = (r == max ? (g - b) / diff : g == max ? 2 + (b - r) / diff : 4 + (r - g) / diff) * 60;
  }

  return [h, s, l];
}

function HSLToRGB(h, s, l) {
  if (s == 0) {
    return [l, l, l];
  }

  var temp2 = l < 0.5 ? l * (1 + s) : l + s - l * s;
  var temp1 = 2 * l - temp2;

  h /= 360;

  var
  rtemp = (h + 1 / 3) % 1,
  gtemp = h,
  btemp = (h + 2 / 3) % 1,
  rgb = [rtemp, gtemp, btemp],
  i = 0;

  for (; i < 3; ++i) {
    rgb[i] = rgb[i] < 1 / 6 ? temp1 + (temp2 - temp1) * 6 * rgb[i] : rgb[i] < 1 / 2 ? temp2 : rgb[i] < 2 / 3 ? temp1 + (temp2 - temp1) * 6 * (2 / 3 - rgb[i]) : temp1;
  }

  return rgb;
}
;

  util.rgbToHsl = RGBToHSL;

  util.hslToRgb = HSLToRGB;

  require("./selection");

  require("./canvas");

  require("./evaluate");

  require("./vector");

}).call(this);
}, "util/vector": function(exports, require, module) {(function() {
  var add, merge, mul, sub, vector, zipWith;

  util.vector = vector = {};

  zipWith = function(f, a, b) {
    var aItem, bItem, index, result, _i, _len;
    result = [];
    for (index = _i = 0, _len = a.length; _i < _len; index = ++_i) {
      aItem = a[index];
      bItem = b[index];
      result.push(f(aItem, bItem));
    }
    return result;
  };

  add = function(x, y) {
    if (!((x != null) && (y != null))) {
      return null;
    }
    return x + y;
  };

  sub = function(x, y) {
    if (!((x != null) && (y != null))) {
      return null;
    }
    return x - y;
  };

  mul = function(x, y) {
    if (!((x != null) && (y != null))) {
      return null;
    }
    return x * y;
  };

  vector.add = function(a, b) {
    return zipWith(add, a, b);
  };

  vector.sub = function(a, b) {
    return zipWith(sub, a, b);
  };

  merge = function(original, extension) {
    if (extension != null) {
      return extension;
    } else {
      return original;
    }
  };

  vector.merge = function(original, extension) {
    return zipWith(merge, original, extension);
  };

  vector.mul = function(scalar, a) {
    var aItem, result, _i, _len;
    result = [];
    for (_i = 0, _len = a.length; _i < _len; _i++) {
      aItem = a[_i];
      result.push(mul(scalar, aItem));
    }
    return result;
  };

  vector.quadrance = function(a) {
    var aItem, result, _i, _len;
    result = 0;
    for (_i = 0, _len = a.length; _i < _len; _i++) {
      aItem = a[_i];
      if (aItem != null) {
        result += aItem * aItem;
      }
    }
    return result;
  };

}).call(this);
}, "view/AppRootView": function(exports, require, module) {(function() {
  R.create("AppRootView", {
    propTypes: {
      appRoot: C.AppRoot
    },
    refreshShaderOverlay: function() {
      return this.refs.shaderOverlay.draw();
    },
    componentDidMount: function() {
      return this.refreshShaderOverlay();
    },
    componentDidUpdate: function() {
      return this.refreshShaderOverlay();
    },
    render: function() {
      return R.div({}, R.PlotLayoutView({
        fn: UI.selectedFn
      }), R.PaletteView({
        appRoot: this.appRoot
      }), R.OutlineView({
        definedFn: UI.selectedFn
      }), R.InspectorView({}), R.SymbolicView({}), R.DraggingView({}), R.ShaderOverlayView({
        ref: "shaderOverlay"
      }));
    }
  });

  R.create("DraggingView", {
    render: function() {
      var _ref;
      return R.div({}, ((_ref = UI.dragging) != null ? _ref.render : void 0) ? R.div({
        className: "DraggingObject",
        style: {
          left: UI.mousePosition.x - UI.dragging.offset.x,
          top: UI.mousePosition.y - UI.dragging.offset.y
        }
      }, UI.dragging.render()) : void 0, UI.dragging ? R.div({
        className: "DraggingOverlay"
      }) : void 0);
    }
  });

  R.create("DebugView", {
    render: function() {
      return R.div({
        style: {
          position: "absolute",
          bottom: 10,
          left: 10,
          zIndex: 99999
        }
      }, R.button({
        onClick: reset
      }, "Reset"));
    }
  });

  key("ctrl+R", function() {
    return reset();
  });

  key("ctrl+S", function() {
    UI.showSymbolic = !UI.showSymbolic;
    return true;
  });

}).call(this);
}, "view/InspectorView": function(exports, require, module) {(function() {
  R.create("InspectorView", {
    render: function() {
      return R.div({
        className: "Inspector"
      }, R.div({
        className: "Header"
      }, "Inspector"), R.div({
        className: "Scroller"
      }, UI.selectedChildFns.length === 1 ? R.InspectorTableView({
        fn: UI.selectedChildFns[0]
      }) : void 0));
    }
  });

  R.create("InspectorTableView", {
    propTypes: {
      fn: C.ChildFn
    },
    render: function() {
      var className, coordIndex, rowIndex, variable;
      return R.table({}, R.tr({
        style: {
          color: config.domainLabelColor
        }
      }, R.th({}), (function() {
        var _i, _ref, _results;
        _results = [];
        for (coordIndex = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; coordIndex = 0 <= _ref ? ++_i : --_i) {
          _results.push(R.th({}, "d" + (coordIndex + 1)));
        }
        return _results;
      })()), R.tr({
        className: "Translate"
      }, R.td({
        className: "icon-move"
      }), this.fn.domainTranslate.map((function(_this) {
        return function(variable) {
          return R.td({
            key: C.id(variable)
          }, R.VariableView({
            variable: variable
          }));
        };
      })(this))), (function() {
        var _i, _ref, _results;
        _results = [];
        for (coordIndex = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; coordIndex = 0 <= _ref ? ++_i : --_i) {
          className = R.cx({
            "icon-resize-full-alt": coordIndex === 0
          });
          _results.push(R.tr({
            key: coordIndex
          }, R.td({
            className: className
          }), (function() {
            var _j, _ref1, _results1;
            _results1 = [];
            for (rowIndex = _j = 0, _ref1 = config.dimensions; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; rowIndex = 0 <= _ref1 ? ++_j : --_j) {
              variable = this.fn.domainTransform[rowIndex][coordIndex];
              _results1.push(R.td({
                key: C.id(variable)
              }, R.VariableView({
                variable: variable
              })));
            }
            return _results1;
          }).call(this)));
        }
        return _results;
      }).call(this), R.tr({
        style: {
          color: config.rangeLabelColor
        }
      }, R.th({}), (function() {
        var _i, _ref, _results;
        _results = [];
        for (coordIndex = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; coordIndex = 0 <= _ref ? ++_i : --_i) {
          _results.push(R.th({}, "r" + (coordIndex + 1)));
        }
        return _results;
      })()), R.tr({
        className: "Translate"
      }, R.td({
        className: "icon-move"
      }), this.fn.rangeTranslate.map((function(_this) {
        return function(variable) {
          return R.td({
            key: C.id(variable)
          }, R.VariableView({
            variable: variable
          }));
        };
      })(this))), (function() {
        var _i, _ref, _results;
        _results = [];
        for (coordIndex = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; coordIndex = 0 <= _ref ? ++_i : --_i) {
          className = R.cx({
            "icon-resize-full-alt": coordIndex === 0
          });
          _results.push(R.tr({
            key: coordIndex
          }, R.td({
            className: className
          }), (function() {
            var _j, _ref1, _results1;
            _results1 = [];
            for (rowIndex = _j = 0, _ref1 = config.dimensions; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; rowIndex = 0 <= _ref1 ? ++_j : --_j) {
              variable = this.fn.rangeTransform[rowIndex][coordIndex];
              _results1.push(R.td({
                key: C.id(variable)
              }, R.VariableView({
                variable: variable
              })));
            }
            return _results1;
          }).call(this)));
        }
        return _results;
      }).call(this));
    }
  });

}).call(this);
}, "view/OutlineView": function(exports, require, module) {(function() {
  R.create("OutlineView", {
    propTypes: {
      definedFn: C.DefinedFn
    },
    render: function() {
      return R.div({
        className: "Outline"
      }, R.LabelView({
        fn: this.definedFn,
        className: "Header"
      }), R.div({
        className: "Scroller"
      }, R.OutlineCombinerToolbar({}), R.OutlineChildrenView({
        compoundFn: this.definedFn
      })));
    }
  });

  R.create("OutlineCombinerToolbar", {
    render: function() {
      return R.div({
        className: "OutlineCombinerToolbar"
      }, R.span({
        className: "OutlineCombinerButton",
        onClick: this._compose
      }, "Compose"), R.span({
        className: "OutlineCombinerButton",
        onClick: this._add
      }, "Add"), R.span({
        className: "OutlineCombinerButton",
        onClick: this._multiply
      }, "Multiply"));
    },
    shouldComponentUpdate: function() {
      return false;
    },
    _compose: function() {
      return Actions.addCompoundFn("composition");
    },
    _add: function() {
      return Actions.addCompoundFn("sum");
    },
    _multiply: function() {
      return Actions.addCompoundFn("product");
    },
    _define: function() {}
  });

  R.create("OutlineChildrenView", {
    propTypes: {
      compoundFn: C.CompoundFn
    },
    render: function() {
      var childFn;
      return R.div({
        className: "OutlineChildren"
      }, (function() {
        var _i, _len, _ref, _results;
        _ref = this.compoundFn.childFns;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childFn = _ref[_i];
          _results.push(R.OutlineItemView({
            childFn: childFn,
            key: C.id(childFn)
          }));
        }
        return _results;
      }).call(this));
    }
  });

  R.create("OutlineItemView", {
    propTypes: {
      childFn: C.ChildFn
    },
    render: function() {
      var canHaveChildren, disclosureClassName, expanded, hovered, itemClassName, rowClassName, selected, _ref;
      if (!this.isDraggingCopy && this.childFn === ((_ref = UI.dragging) != null ? _ref.childFn : void 0)) {
        return R.div({
          className: "Placeholder",
          style: {
            height: UI.dragging.placeholderHeight
          }
        });
      }
      canHaveChildren = this.childFn.fn instanceof C.CompoundFn;
      expanded = UI.isChildFnExpanded(this.childFn);
      selected = _.contains(UI.selectedChildFns, this.childFn);
      hovered = this.childFn === UI.hoveredChildFn;
      itemClassName = R.cx({
        OutlineItem: true,
        Invisible: !this.childFn.visible
      });
      rowClassName = R.cx({
        OutlineRow: true,
        Selected: selected,
        Hovered: hovered
      });
      disclosureClassName = R.cx({
        DisclosureTriangle: true,
        Expanded: expanded
      });
      return R.div({
        className: itemClassName
      }, R.div({
        className: rowClassName,
        onMouseDown: this._onRowMouseDown,
        onMouseEnter: this._onRowMouseEnter,
        onMouseLeave: this._onRowMouseLeave
      }, R.div({
        className: "OutlineVisible Interactive",
        onClick: this._onVisibleClick
      }, R.div({
        className: "icon-eye"
      })), canHaveChildren ? R.div({
        className: "OutlineDisclosure Interactive",
        onClick: this._onDisclosureClick
      }, R.div({
        className: disclosureClassName
      })) : void 0, R.OutlineThumbnailView({
        childFn: this.childFn
      }), R.OutlineInternalsView({
        fn: this.childFn.fn
      })), canHaveChildren && expanded ? R.OutlineChildrenView({
        compoundFn: this.childFn.fn
      }) : void 0);
    },
    _onDisclosureClick: function() {
      return Actions.toggleChildFnExpanded(this.childFn);
    },
    _onVisibleClick: function() {
      return Actions.toggleChildFnVisible(this.childFn);
    },
    _onRowMouseDown: function(e) {
      var childFn, el, myHeight, myWidth, offset, parentCompoundFn, rect;
      if (e.target.closest(".Interactive, select, [contenteditable]")) {
        return;
      }
      if (key.command || key.shift) {
        if (_.contains(UI.selectedChildFns, this.childFn)) {
          util.onceDragConsummated(e, null, (function(_this) {
            return function() {
              return Actions.toggleSelectChildFn(_this.childFn);
            };
          })(this));
        } else {
          Actions.toggleSelectChildFn(this.childFn);
        }
      } else {
        Actions.selectChildFn(this.childFn);
      }
      util.preventDefault(e);
      el = this.getDOMNode();
      rect = el.getMarginRect();
      myWidth = rect.width;
      myHeight = rect.height;
      offset = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top
      };
      UI.dragging = {
        cursor: "-webkit-grabbing"
      };
      if (key.command) {
        childFn = this.childFn.duplicate();
        Actions.setChildFnExpanded(childFn, false);
        parentCompoundFn = null;
      } else {
        childFn = this.childFn;
        parentCompoundFn = this.lookup("compoundFn");
      }
      return util.onceDragConsummated(e, (function(_this) {
        return function() {
          return UI.dragging = {
            cursor: "-webkit-grabbing",
            offset: offset,
            placeholderHeight: myHeight,
            childFn: childFn,
            render: function() {
              return R.div({
                style: {
                  width: myWidth,
                  height: myHeight,
                  overflow: "hidden",
                  "background-color": "#fff"
                }
              }, R.OutlineItemView({
                childFn: childFn,
                isDraggingCopy: true
              }));
            },
            onMove: function() {
              var bestDrop, bestQuadrance, checkFit, draggingPosition, droppedPosition, index, outlineChildrenEl, outlineChildrenEls, outlineItemEl, outlineItemEls, placeholderEl, _i, _j, _len, _len1;
              draggingPosition = {
                x: UI.mousePosition.x - offset.x,
                y: UI.mousePosition.y - offset.y
              };
              placeholderEl = document.querySelector(".Placeholder");
              if (placeholderEl != null) {
                placeholderEl.style.display = "none";
              }
              bestQuadrance = 40 * 40;
              bestDrop = null;
              checkFit = function(droppedPosition, outlineChildrenEl, index) {
                var dx, dy, quadrance;
                dx = draggingPosition.x - droppedPosition.x;
                dy = draggingPosition.y - droppedPosition.y;
                quadrance = dx * dx + dy * dy;
                if (quadrance < bestQuadrance) {
                  bestQuadrance = quadrance;
                  return bestDrop = {
                    outlineChildrenEl: outlineChildrenEl,
                    index: index
                  };
                }
              };
              outlineChildrenEls = document.querySelectorAll(".Outline .OutlineChildren");
              for (_i = 0, _len = outlineChildrenEls.length; _i < _len; _i++) {
                outlineChildrenEl = outlineChildrenEls[_i];
                outlineItemEls = _.filter(outlineChildrenEl.childNodes, function(el) {
                  return el.classList.contains("OutlineItem");
                });
                for (index = _j = 0, _len1 = outlineItemEls.length; _j < _len1; index = ++_j) {
                  outlineItemEl = outlineItemEls[index];
                  rect = outlineItemEl.getBoundingClientRect();
                  droppedPosition = {
                    x: rect.left,
                    y: rect.top
                  };
                  checkFit(droppedPosition, outlineChildrenEl, index);
                }
                rect = outlineChildrenEl.getBoundingClientRect();
                droppedPosition = {
                  x: rect.left,
                  y: rect.bottom
                };
                checkFit(droppedPosition, outlineChildrenEl, index);
              }
              if (placeholderEl != null) {
                placeholderEl.style.display = "";
              }
              if (parentCompoundFn) {
                Actions.removeChildFn(parentCompoundFn, childFn);
                parentCompoundFn = null;
              }
              if (bestDrop) {
                parentCompoundFn = bestDrop.outlineChildrenEl.dataFor.compoundFn;
                return Actions.insertChildFn(parentCompoundFn, childFn, bestDrop.index);
              }
            }
          };
        };
      })(this));
    },
    _onRowMouseEnter: function() {
      return Actions.hoverChildFn(this.childFn);
    },
    _onRowMouseLeave: function() {
      return Actions.hoverChildFn(null);
    }
  });

  R.create("OutlineInternalsView", {
    propTypes: {
      fn: C.Fn
    },
    render: function() {
      return R.div({
        className: "OutlineInternals"
      }, this.fn instanceof C.BuiltInFn ? R.LabelView({
        fn: this.fn
      }) : this.fn instanceof C.DefinedFn ? R.LabelView({
        fn: this.fn
      }) : this.fn instanceof C.CompoundFn ? R.CombinerView({
        compoundFn: this.fn
      }) : void 0);
    }
  });

  R.create("OutlineThumbnailView", {
    propTypes: {
      childFn: C.ChildFn
    },
    render: function() {
      var plotLayout;
      plotLayout = UI.selectedFn.plotLayout;
      return R.div({
        className: "OutlineThumbnail"
      }, R.ThumbnailPlotLayoutView({
        plotLayout: plotLayout,
        fn: this.childFn
      }));
    }
  });

  R.create("LabelView", {
    propTypes: {
      fn: C.Fn
    },
    render: function() {
      var className;
      className = R.cx({
        Label: true,
        Interactive: !(this.fn instanceof C.BuiltInFn)
      });
      if (this.className) {
        className += " " + this.className;
      }
      if (this.fn instanceof C.BuiltInFn) {
        return R.div({
          className: className
        }, this.fn.label);
      } else {
        return R.TextFieldView({
          className: className,
          value: this.fn.label,
          onInput: this._onInput
        });
      }
    },
    _onInput: function(newValue) {
      return Actions.setFnLabel(this.fn, newValue);
    }
  });

  R.create("CombinerView", {
    propTypes: {
      compoundFn: C.CompoundFn
    },
    render: function() {
      return R.select({
        value: this.compoundFn.combiner,
        onChange: this._onChange
      }, R.option({
        value: "sum"
      }, "Add"), R.option({
        value: "product"
      }, "Multiply"), R.option({
        value: "composition"
      }, "Compose"));
    },
    _onChange: function(e) {
      var value;
      value = e.target.selectedOptions[0].value;
      return Actions.setCompoundFnCombiner(this.compoundFn, value);
    }
  });

}).call(this);
}, "view/PaletteView": function(exports, require, module) {(function() {
  R.create("PaletteView", {
    propTypes: {
      appRoot: C.AppRoot
    },
    render: function() {
      return R.div({
        className: "Palette"
      }, R.div({
        className: "Header"
      }, "Library"), R.div({
        className: "Scroller"
      }, R.div({
        className: "PaletteHeader"
      }, "Built In Functions"), builtIn.fns.map((function(_this) {
        return function(fn) {
          return R.DefinitionView({
            fn: fn,
            key: C.id(fn)
          });
        };
      })(this)), R.div({
        className: "PaletteHeader"
      }, "Custom Functions"), this.appRoot.fns.map((function(_this) {
        return function(fn) {
          return R.DefinitionView({
            fn: fn,
            key: C.id(fn)
          });
        };
      })(this)), R.div({
        className: "AddDefinition"
      }, R.button({
        className: "AddButton",
        onClick: this._onAddButtonClick
      }))));
    },
    _onAddButtonClick: function() {
      return Actions.addDefinedFn();
    }
  });

  R.create("DefinitionView", {
    propTypes: {
      fn: C.Fn
    },
    render: function() {
      var className, plotLayout;
      if (this.fn instanceof C.BuiltInFn) {
        plotLayout = builtIn.defaultPlotLayout;
      } else {
        plotLayout = this.fn.plotLayout;
      }
      className = R.cx({
        Definition: true,
        Selected: UI.selectedFn === this.fn
      });
      return R.div({
        className: className,
        onMouseDown: this._onMouseDown
      }, R.ThumbnailPlotLayoutView({
        plotLayout: plotLayout,
        fn: this.fn
      }), R.LabelView({
        fn: this.fn
      }));
    },
    _onMouseDown: function(e) {
      var addChildFn, selectFn;
      if (e.target.matches(".Interactive")) {
        return;
      }
      util.preventDefault(e);
      addChildFn = (function(_this) {
        return function() {
          return Actions.addChildFn(_this.fn);
        };
      })(this);
      selectFn = (function(_this) {
        return function() {
          return Actions.selectFn(_this.fn);
        };
      })(this);
      return util.onceDragConsummated(e, addChildFn, selectFn);
    }
  });

}).call(this);
}, "view/PlotLayoutView": function(exports, require, module) {(function() {
  R.create("PlotLayoutView", {
    propTypes: {
      fn: C.DefinedFn
    },
    render: function() {
      var h, index, plot, plotLocations, w, x, y;
      plotLocations = this.fn.plotLayout.getPlotLocations();
      return R.div({
        className: "PlotLayout"
      }, (function() {
        var _i, _len, _ref, _results;
        _results = [];
        for (index = _i = 0, _len = plotLocations.length; _i < _len; index = ++_i) {
          _ref = plotLocations[index], plot = _ref.plot, x = _ref.x, y = _ref.y, w = _ref.w, h = _ref.h;
          _results.push(R.div({
            className: "PlotLocation",
            style: {
              left: x * 100 + "%",
              top: y * 100 + "%",
              width: w * 100 + "%",
              height: h * 100 + "%"
            },
            key: index
          }, R.PlotView({
            fn: this.fn,
            plot: plot,
            showSliceControl: plotLocations.length > 1
          })));
        }
        return _results;
      }).call(this), R.div({
        className: "SettingsButton Interactive",
        onClick: this._onSettingsButtonClick
      }, R.div({
        className: "icon-cog"
      })));
    },
    _onSettingsButtonClick: function() {
      var plotLayout;
      plotLayout = this.fn.plotLayout;
      if (plotLayout.display2d) {
        plotLayout.display2d = false;
        return plotLayout.plots[0].type = "cartesian";
      } else {
        plotLayout.display2d = true;
        plotLayout.plots[0].type = "colorMap";
        plotLayout.plots[1].type = "cartesian";
        return plotLayout.plots[2].type = "cartesian2";
      }
    }
  });

  R.create("PlotView", {
    propTypes: {
      fn: C.DefinedFn,
      plot: C.Plot,
      showSliceControl: Boolean
    },
    _getExpandedChildFns: function() {
      var recurse, result;
      result = [];
      recurse = function(childFns) {
        var childFn, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = childFns.length; _i < _len; _i++) {
          childFn = childFns[_i];
          if (!childFn.visible) {
            continue;
          }
          result.push(childFn);
          if (UI.isChildFnExpanded(childFn) && childFn.fn instanceof C.CompoundFn) {
            _results.push(recurse(childFn.fn.childFns));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };
      recurse(this.fn.childFns);
      return result;
    },
    _getWorldMouseCoords: function() {
      var rect, x, y;
      rect = this.getDOMNode().getBoundingClientRect();
      x = UI.mousePosition.x - (rect.left + rect.width / 2);
      y = UI.mousePosition.y - (rect.top + rect.height / 2);
      y *= -1;
      return this.plot.toWorld({
        x: x,
        y: y
      });
    },
    _findHitTarget: function() {
      var childFn, error, evaluated, found, foundError, inputVal, mask, maxDistance, maxQuadrance, offset, outputMask, outputVal, pixelSize, point, _i, _len, _ref;
      pixelSize = this.plot.getPixelSize();
      maxDistance = config.hitTolerance * pixelSize;
      maxQuadrance = maxDistance * maxDistance;
      point = this._getWorldMouseCoords();
      mask = this.plot.getMask();
      outputMask = mask.slice(config.dimensions);
      inputVal = point.slice(0, config.dimensions);
      outputVal = point.slice(config.dimensions);
      found = null;
      foundError = maxQuadrance;
      _ref = this._getExpandedChildFns();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        childFn = _ref[_i];
        evaluated = childFn.evaluate(inputVal);
        offset = numeric.sub(outputVal, evaluated);
        offset = numeric.mul(offset, outputMask);
        error = numeric.norm2Squared(offset);
        if (error < foundError) {
          found = childFn;
          foundError = error;
        }
      }
      return found;
    },
    render: function() {
      var childFn, expandedChildFns, fns, _i, _j, _len, _len1, _ref;
      fns = [];
      if (this.plot.type === "colorMap") {
        fns.push({
          fn: this.fn
        });
      } else {
        expandedChildFns = this._getExpandedChildFns();
        for (_i = 0, _len = expandedChildFns.length; _i < _len; _i++) {
          childFn = expandedChildFns[_i];
          fns.push({
            fn: childFn,
            color: config.color.child
          });
        }
        if (UI.hoveredChildFn && _.contains(expandedChildFns, UI.hoveredChildFn)) {
          fns.push({
            fn: UI.hoveredChildFn,
            color: config.color.hovered
          });
        }
        fns.push({
          fn: this.fn,
          color: config.color.main
        });
        _ref = UI.selectedChildFns;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          childFn = _ref[_j];
          fns.push({
            fn: childFn,
            color: config.color.selected
          });
        }
        fns = _.reject(fns, function(fnHolder, fnIndex) {
          var i, _k, _ref1, _ref2;
          for (i = _k = _ref1 = fnIndex + 1, _ref2 = fns.length; _ref1 <= _ref2 ? _k < _ref2 : _k > _ref2; i = _ref1 <= _ref2 ? ++_k : --_k) {
            if (fns[i].fn === fnHolder.fn) {
              return true;
            }
          }
          return false;
        });
      }
      return R.div({
        className: "PlotContainer",
        onMouseDown: this._onMouseDown,
        onWheel: this._onWheel,
        onMouseMove: this._onMouseMove,
        onMouseLeave: this._onMouseLeave
      }, R.GridView({
        plot: this.plot,
        isThumbnail: false
      }), R.ShaderCartesianView({
        plot: this.plot,
        fns: fns,
        isThumbnail: false
      }), this.showSliceControl ? R.SliceControlsView({
        plot: this.plot
      }) : void 0, UI.selectedChildFns.length === 1 ? R.ChildFnControlsView({
        childFn: UI.selectedChildFns[0],
        plot: this.plot
      }) : void 0);
    },
    _onMouseMove: function() {
      return Actions.hoverChildFn(this._findHitTarget());
    },
    _onMouseLeave: function() {
      return Actions.hoverChildFn(null);
    },
    _onMouseDown: function(e) {
      if (e.target.closest(".Interactive")) {
        return;
      }
      util.preventDefault(e);
      this._startPan(e);
      return util.onceDragConsummated(e, null, (function(_this) {
        return function() {
          return _this._changeSelection();
        };
      })(this));
    },
    _onWheel: function(e) {
      var plotLayout, scaleFactor, zoomCenter;
      e.preventDefault();
      if (Math.abs(e.deltaY) <= 1) {
        return;
      }
      scaleFactor = 1.1;
      if (e.deltaY < 0) {
        scaleFactor = 1 / scaleFactor;
      }
      zoomCenter = this._getWorldMouseCoords();
      plotLayout = this.fn.plotLayout;
      return Actions.zoomPlotLayout(plotLayout, zoomCenter, scaleFactor);
    },
    _changeSelection: function() {
      var childFn;
      childFn = this._findHitTarget();
      if (key.command || key.shift) {
        if (childFn != null) {
          return Actions.toggleSelectChildFn(childFn);
        }
      } else {
        return Actions.selectChildFn(childFn);
      }
    },
    _startPan: function(e) {
      var from;
      from = this._getWorldMouseCoords();
      return UI.dragging = {
        cursor: config.cursor.grabbing,
        onMove: (function(_this) {
          return function(e) {
            var plotLayout, to;
            to = _this._getWorldMouseCoords();
            plotLayout = _this.fn.plotLayout;
            return Actions.panPlotLayout(plotLayout, from, to);
          };
        })(this)
      };
    },
    _onSettingsButtonClick: function() {
      if (this.plot.type === "cartesian") {
        return this.plot.type = "colorMap";
      } else {
        return this.plot.type = "cartesian";
      }
    }
  });

  R.create("ChildFnControlsView", {
    propTypes: {
      childFn: C.ChildFn,
      plot: C.Plot
    },
    render: function() {
      var transformInfo;
      return R.div({
        className: "Interactive PointControlContainer"
      }, R.PointControlView({
        position: this._getTranslatePosition(),
        onMove: this._setTranslatePosition
      }), (function() {
        var _i, _len, _ref, _results;
        _ref = this._getVisibleTransforms();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          transformInfo = _ref[_i];
          _results.push(R.PointControlView({
            position: this._getTransformPosition(transformInfo),
            onMove: this._setTransformPosition(transformInfo),
            key: transformInfo.space + transformInfo.basisVectorIndex
          }));
        }
        return _results;
      }).call(this));
    },
    _snap: function(value) {
      var digitPrecision, largeSpacing, nearestSnap, pixelSize, precision, smallSpacing, snapTolerance, _ref;
      pixelSize = this.plot.getPixelSize();
      _ref = util.canvas.getSpacing(pixelSize), largeSpacing = _ref.largeSpacing, smallSpacing = _ref.smallSpacing;
      snapTolerance = pixelSize * config.snapTolerance;
      nearestSnap = Math.round(value / largeSpacing) * largeSpacing;
      if (Math.abs(value - nearestSnap) < snapTolerance) {
        value = nearestSnap;
        digitPrecision = Math.floor(Math.log(largeSpacing) / Math.log(10));
        precision = Math.pow(10, digitPrecision);
        return util.floatToString(value, precision);
      }
      digitPrecision = Math.floor(Math.log(pixelSize) / Math.log(10));
      precision = Math.pow(10, digitPrecision);
      return util.floatToString(value, precision);
    },
    _getTranslatePosition: function() {
      var translate;
      translate = [].concat(this.childFn.domainTranslate.map(function(v) {
        return v.getValue();
      }), this.childFn.rangeTranslate.map(function(v) {
        return v.getValue();
      }));
      return this.plot.toPixel(translate);
    },
    _setTranslatePosition: function(_arg) {
      var coord, isRepresented, translate, value, valueString, variable, x, y, _i, _len, _ref, _results;
      x = _arg.x, y = _arg.y;
      translate = this.plot.toWorld({
        x: x,
        y: y
      });
      _ref = this.plot.getMask();
      _results = [];
      for (coord = _i = 0, _len = _ref.length; _i < _len; coord = ++_i) {
        isRepresented = _ref[coord];
        if (isRepresented) {
          value = translate[coord];
          valueString = this._snap(value);
          variable = coord < translate.length / 2 ? this.childFn.domainTranslate[coord] : this.childFn.rangeTranslate[coord - translate.length / 2];
          _results.push(Actions.setVariableValueString(variable, valueString));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    },
    _getVisibleTransforms: function() {
      var basisVector, basisVectorIndex, indexOffset, isVisible, mask, space, visibleTransforms, _i, _j, _k, _len, _ref, _ref1, _ref2, _results;
      mask = this.plot.getMask();
      visibleTransforms = [];
      _ref = ["domain", "range"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        space = _ref[_i];
        for (basisVectorIndex = _j = 0, _ref1 = config.dimensions; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; basisVectorIndex = 0 <= _ref1 ? ++_j : --_j) {
          basisVector = this.childFn.getBasisVector(space, basisVectorIndex);
          indexOffset = space === "domain" ? 0 : config.dimensions;
          isVisible = _.all((function() {
            _results = [];
            for (var _k = 0, _ref2 = config.dimensions; 0 <= _ref2 ? _k < _ref2 : _k > _ref2; 0 <= _ref2 ? _k++ : _k--){ _results.push(_k); }
            return _results;
          }).apply(this), (function(_this) {
            return function(coord) {
              if (mask[coord + indexOffset] === 1) {
                return true;
              }
              if (basisVector[coord] === _this.plot.focus[coord + indexOffset]) {
                return true;
              }
              return false;
            };
          })(this));
          if (isVisible) {
            visibleTransforms.push({
              space: space,
              basisVectorIndex: basisVectorIndex,
              basisVector: basisVector
            });
          }
        }
      }
      return visibleTransforms;
    },
    _getTransformPosition: function(transformInfo) {
      var transform, translate, worldPosition;
      translate = [].concat(this.childFn.domainTranslate.map(function(v) {
        return v.getValue();
      }), this.childFn.rangeTranslate.map(function(v) {
        return v.getValue();
      }));
      if (transformInfo.space === "domain") {
        transform = [].concat(transformInfo.basisVector, util.constructVector(config.dimensions, 0));
      } else {
        transform = [].concat(util.constructVector(config.dimensions, 0), transformInfo.basisVector);
      }
      worldPosition = numeric.add(translate, transform);
      return this.plot.toPixel(worldPosition);
    },
    _setTransformPosition: function(transformInfo) {
      return (function(_this) {
        return function(_arg) {
          var mask, newBasisVector, offset, point, translate, valueStrings, x, y;
          x = _arg.x, y = _arg.y;
          translate = [].concat(_this.childFn.domainTranslate.map(function(v) {
            return v.getValue();
          }), _this.childFn.rangeTranslate.map(function(v) {
            return v.getValue();
          }));
          point = _this.plot.toWorld({
            x: x,
            y: y
          });
          offset = numeric.sub(point, translate);
          if (transformInfo.space === "domain") {
            newBasisVector = offset.slice(0, config.dimensions);
            mask = _this.plot.getMask().slice(0, config.dimensions);
          } else {
            newBasisVector = offset.slice(config.dimensions);
            mask = _this.plot.getMask().slice(config.dimensions);
          }
          newBasisVector = util.vectorMask(newBasisVector, transformInfo.basisVector, mask);
          valueStrings = newBasisVector.map(function(value) {
            return _this._snap(value);
          });
          return Actions.setBasisVector(_this.childFn, transformInfo.space, transformInfo.basisVectorIndex, valueStrings);
        };
      })(this);
    }
  });

  R.create("PointControlView", {
    propTypes: {
      position: Object,
      onMove: Function
    },
    render: function() {
      return R.div({
        className: "PointControl",
        onMouseDown: this._onMouseDown,
        style: {
          left: this.position.x,
          top: -this.position.y
        }
      });
    },
    _onMouseDown: function(e) {
      var container, rect;
      util.preventDefault(e);
      container = this.getDOMNode().closest(".PointControlContainer");
      rect = container.getBoundingClientRect();
      return UI.dragging = {
        onMove: (function(_this) {
          return function(e) {
            var x, y;
            x = e.clientX - rect.left;
            y = e.clientY - rect.top;
            y *= -1;
            return _this.onMove({
              x: x,
              y: y
            });
          };
        })(this)
      };
    }
  });

  R.create("SliceControlsView", {
    propTypes: {
      plot: C.Plot
    },
    render: function() {
      var index, slice;
      return R.div({
        className: "Interactive PointControlContainer"
      }, (function() {
        var _i, _len, _ref, _results;
        _ref = this._getSlices();
        _results = [];
        for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
          slice = _ref[index];
          _results.push(R.LineControlView({
            position: slice,
            onMove: this._onMove,
            key: index
          }));
        }
        return _results;
      }).call(this));
    },
    _getSlices: function() {
      var coord, dimension, dimensionIndex, pixelFocus, slices, _i, _j, _len, _ref, _ref1;
      slices = [];
      pixelFocus = this.plot.toPixel(this.plot.focus);
      _ref = this.plot.getDimensions();
      for (dimensionIndex = _i = 0, _len = _ref.length; _i < _len; dimensionIndex = ++_i) {
        dimension = _ref[dimensionIndex];
        for (coord = _j = 0, _ref1 = config.dimensions; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; coord = 0 <= _ref1 ? ++_j : --_j) {
          if (dimension[coord] === 1) {
            if (dimensionIndex === 0) {
              slices.push({
                x: pixelFocus.x
              });
            } else if (dimensionIndex === 1) {
              slices.push({
                y: pixelFocus.y
              });
            }
          }
        }
      }
      return slices;
    },
    _onMove: function(position) {
      var focus, largeSpacing, pixelFocus, pixelSize, plotLayout, smallSpacing, snapTolerance, _ref;
      pixelFocus = this.plot.toPixel(this.plot.focus);
      pixelFocus = _.extend(pixelFocus, position);
      focus = this.plot.toWorld(pixelFocus);
      pixelSize = this.plot.getPixelSize();
      _ref = util.canvas.getSpacing(pixelSize), largeSpacing = _ref.largeSpacing, smallSpacing = _ref.smallSpacing;
      snapTolerance = pixelSize * config.snapTolerance;
      focus = focus.map(function(value) {
        var nearestSnap;
        nearestSnap = Math.round(value / largeSpacing) * largeSpacing;
        if (Math.abs(value - nearestSnap) < snapTolerance) {
          return nearestSnap;
        } else {
          return value;
        }
      });
      plotLayout = this.lookup("fn").plotLayout;
      return Actions.setPlotLayoutFocus(plotLayout, focus);
    }
  });

  R.create("LineControlView", {
    propTypes: {
      position: Object,
      onMove: Function
    },
    render: function() {
      return R.div({
        className: "LineControl",
        onMouseDown: this._onMouseDown,
        style: {
          left: this.position.x != null ? this.position.x : "-50%",
          top: this.position.y != null ? -this.position.y : "-50%",
          width: this.position.x != null ? "" : "100%",
          height: this.position.y != null ? "" : "100%"
        }
      });
    },
    _onMouseDown: function(e) {
      var container, rect;
      util.preventDefault(e);
      container = this.getDOMNode().closest(".PointControlContainer");
      rect = container.getBoundingClientRect();
      return UI.dragging = {
        onMove: (function(_this) {
          return function(e) {
            var x, y;
            x = e.clientX - rect.left;
            y = e.clientY - rect.top;
            y *= -1;
            if (_this.position.x != null) {
              return _this.onMove({
                x: x
              });
            } else {
              return _this.onMove({
                y: y
              });
            }
          };
        })(this)
      };
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

  require("./ShaderOverlayView");

  require("./PaletteView");

  require("./PlotLayoutView");

  require("./ThumbnailPlotLayoutView");

  require("./OutlineView");

  require("./InspectorView");

  require("./VariableView");

  require("./SymbolicView");

  require("./plot/GridView");

  require("./plot/ShaderCartesianView");

}).call(this);
}, "view/ShaderOverlayView": function(exports, require, module) {(function() {
  var Glod, addSelectedChildFnUniforms, bufferCartesianSamples, bufferQuad, createCartesianProgram, createColorMapProgram, createProgramFromSrc, drawCartesianProgram, drawColorMapProgram, packMatrix, setViewport,
    __hasProp = {}.hasOwnProperty;

  Glod = require("./plot/glod");

  R.create("ShaderOverlayView", {
    initializeGlod: function() {
      var canvas, gl;
      this.glod = new Glod();
      canvas = this.getDOMNode();
      this.glod.canvas(canvas, {
        antialias: true
      });
      gl = this.glod.gl();
      gl.enable(gl.SCISSOR_TEST);
      gl.lineWidth(1.25);
      bufferQuad(this.glod);
      bufferCartesianSamples(this.glod, 20000);
      return this.programs = {};
    },
    sizeCanvas: function() {
      var canvas, rect;
      canvas = this.getDOMNode();
      rect = canvas.getBoundingClientRect();
      if (canvas.width !== rect.width || canvas.height !== rect.height) {
        canvas.width = rect.width;
        return canvas.height = rect.height;
      }
    },
    draw: function() {
      var bounds, canvas, clippingRect, fnHolder, fns, glsl, junk, name, plot, rect, scaleFactor, shaderEl, shaderEls, shaderView, usedPrograms, _i, _j, _len, _len1, _ref, _results;
      canvas = this.getDOMNode();
      usedPrograms = {};
      shaderEls = document.querySelectorAll(".Shader");
      for (_i = 0, _len = shaderEls.length; _i < _len; _i++) {
        shaderEl = shaderEls[_i];
        if (!shaderEl.isOnScreen()) {
          continue;
        }
        rect = shaderEl.getBoundingClientRect();
        clippingRect = shaderEl.getClippingRect();
        if (clippingRect.height <= 0 || clippingRect.width <= 0) {
          continue;
        }
        setViewport(this.glod, rect, clippingRect);
        shaderView = shaderEl.dataFor;
        fns = shaderView.fns;
        plot = shaderView.plot;
        if (shaderView.isThumbnail) {
          scaleFactor = window.innerHeight / rect.height;
        } else {
          scaleFactor = 1;
        }
        for (_j = 0, _len1 = fns.length; _j < _len1; _j++) {
          fnHolder = fns[_j];
          glsl = Compiler.getGlsl(fnHolder.fn);
          name = plot.type + "," + glsl;
          if (!this.programs[name]) {
            if (plot.type === "cartesian" || plot.type === "cartesian2") {
              createCartesianProgram(this.glod, name, glsl);
            } else if (plot.type === "colorMap") {
              createColorMapProgram(this.glod, name, glsl);
            }
            this.programs[name] = true;
          }
          usedPrograms[name] = true;
          if (plot.type === "cartesian" || plot.type === "cartesian2") {
            drawCartesianProgram(this.glod, name, fnHolder.color, plot, rect.width, rect.height, scaleFactor);
          } else if (plot.type === "colorMap") {
            bounds = plot.getScaledBounds(rect.width, rect.height, scaleFactor);
            drawColorMapProgram(this.glod, name, bounds);
          }
        }
      }
      _ref = this.programs;
      _results = [];
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        junk = _ref[name];
        if (!usedPrograms[name]) {
          delete this.glod._programs[name];
          _results.push(delete this.programs[name]);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    },
    getAdditionalCode: function() {
      var additionalCode, exprString, id, vecType, _ref;
      additionalCode = "";
      vecType = util.glslVectorType(config.dimensions);
      _ref = Compiler.getAllDefinedFnExprStrings();
      for (id in _ref) {
        if (!__hasProp.call(_ref, id)) continue;
        exprString = _ref[id];
        additionalCode += "" + vecType + " " + id + "(" + vecType + " inputVal) {return " + exprString + ";}\n";
      }
      return additionalCode;
    },
    handleResize: function() {
      this.sizeCanvas();
      return this.draw();
    },
    componentDidMount: function() {
      this.initializeGlod();
      this.sizeCanvas();
      return window.addEventListener("resize", this.handleResize);
    },
    componentWillUnmount: function() {
      return window.removeEventListener("resize", this.handleResize);
    },
    render: function() {
      return R.canvas({
        className: "ShaderOverlay"
      });
    }
  });

  createProgramFromSrc = function(glod, name, vertex, fragment) {
    Glod.preprocessed[name] = {
      name: name,
      fragment: fragment,
      vertex: vertex
    };
    delete glod._programs[name];
    return glod.createProgram(name);
  };

  setViewport = function(glod, rect, clippingRect) {
    var canvas, gl, h, sh, sw, sx, sy, w, x, y;
    gl = glod.gl();
    canvas = glod.canvas();
    x = rect.left;
    y = canvas.height - rect.bottom;
    w = rect.width;
    h = rect.height;
    sx = clippingRect.left;
    sy = canvas.height - clippingRect.bottom;
    sw = clippingRect.width;
    sh = clippingRect.height;
    gl.viewport(x, y, w, h);
    gl.scissor(sx, sy, sw, sh);
    return glod.viewport_ = {
      x: x,
      y: y,
      w: w,
      h: h
    };
  };

  bufferQuad = function(glod) {
    return glod.createVBO("quad").uploadCCWQuad("quad");
  };

  bufferCartesianSamples = function(glod, numSamples) {
    var i, samplesArray, _i;
    samplesArray = [];
    for (i = _i = 0; 0 <= numSamples ? _i <= numSamples : _i >= numSamples; i = 0 <= numSamples ? ++_i : --_i) {
      samplesArray.push(i);
    }
    if (glod.hasVBO("samples")) {
      glod.deleteVBO("samples");
    }
    return glod.createVBO("samples").bufferDataStatic("samples", new Float32Array(samplesArray));
  };

  createCartesianProgram = function(glod, name, glsl) {
    var fragment, matType, vecType, vertex;
    vecType = util.glslVectorType(config.dimensions);
    matType = util.glslMatrixType(config.dimensions);
    vertex = "precision highp float;\nprecision highp int;\n\nattribute float sample;\n\nuniform " + vecType + " domainStart, domainStep;\n\nuniform " + vecType + " domainCenter, rangeCenter;\nuniform " + matType + " domainTransform, rangeTransform;\n\nuniform " + vecType + " selectedDomainTranslate, selectedRangeTranslate;\nuniform " + matType + " selectedDomainTransformInv, selectedRangeTransform;\n\nuniform vec2 pixelScale;\n\n" + glsl + "\n\nvoid main() {\n  " + vecType + " inputVal, outputVal;\n  inputVal = domainStart + domainStep * sample;\n  outputVal = mainFn(inputVal);\n\n  " + vecType + " position = domainTransform * (inputVal - domainCenter) +\n                        rangeTransform * (outputVal - rangeCenter);\n\n  gl_Position = vec4(vec2(position.x, position.y) * pixelScale, 0., 1.);\n}";
    fragment = "precision highp float;\nprecision highp int;\n\nuniform vec4 color;\n\nvoid main() {\n  gl_FragColor = color;\n}";
    return createProgramFromSrc(glod, name, vertex, fragment);
  };

  drawCartesianProgram = function(glod, name, color, plot, width, height, scaleFactor) {
    var dimensions, domainCenter, domainEnd, domainStart, domainStep, domainTransform, domainTransformSmall, isHorizontal, numSamples, pixelScale, pixelSize, rangeCenter, rangeTransform, rangeTransformSmall;
    dimensions = plot.getDimensions();
    pixelSize = plot.getPixelSize();
    width *= scaleFactor;
    height *= scaleFactor;
    isHorizontal = dimensions[0][0] === 1 || dimensions[1][0] === 1;
    if (isHorizontal) {
      domainStart = plot.toWorld({
        x: -width / 2,
        y: 0
      }).slice(0, config.dimensions);
      domainEnd = plot.toWorld({
        x: width / 2,
        y: 0
      }).slice(0, config.dimensions);
      numSamples = (width / scaleFactor) / config.resolution;
    } else {
      domainStart = plot.toWorld({
        x: 0,
        y: -height / 2
      }).slice(0, config.dimensions);
      domainEnd = plot.toWorld({
        x: 0,
        y: height / 2
      }).slice(0, config.dimensions);
      numSamples = (height / scaleFactor) / config.resolution;
    }
    domainStep = numeric.div(numeric.sub(domainEnd, domainStart), numSamples);
    domainCenter = plot.center.slice(0, config.dimensions);
    rangeCenter = plot.center.slice(config.dimensions);
    domainTransformSmall = numeric.getBlock(dimensions, [0, 0], [1, config.dimensions - 1]);
    rangeTransformSmall = numeric.getBlock(dimensions, [0, config.dimensions], [1, config.dimensions * 2 - 1]);
    domainTransform = numeric.identity(config.dimensions);
    rangeTransform = numeric.identity(config.dimensions);
    numeric.setBlock(domainTransform, [0, 0], [1, config.dimensions - 1], domainTransformSmall);
    numeric.setBlock(rangeTransform, [0, 0], [1, config.dimensions - 1], rangeTransformSmall);
    pixelScale = [(1 / pixelSize) * (1 / (width / 2)), (1 / pixelSize) * (1 / (height / 2))];
    glod.begin(name);
    glod.pack("samples", "sample");
    glod.valuev("color", color);
    glod.valuev("domainStart", domainStart);
    glod.valuev("domainStep", domainStep);
    glod.valuev("domainCenter", domainCenter);
    glod.valuev("rangeCenter", rangeCenter);
    glod.valuev("domainTransform", util.glslMatrixArray(domainTransform));
    glod.valuev("rangeTransform", util.glslMatrixArray(rangeTransform));
    glod.valuev("pixelScale", pixelScale);
    addSelectedChildFnUniforms(glod);
    glod.ready().lineStrip().drawArrays(0, numSamples);
    return glod.end();
  };

  createColorMapProgram = function(glod, name, glsl) {
    var fragment, matType, vecType, vertex;
    vecType = util.glslVectorType(config.dimensions);
    matType = util.glslMatrixType(config.dimensions);
    vertex = "precision highp float;\nprecision highp int;\n\nattribute vec4 position;\nvarying vec2 vPosition;\n\nvoid main() {\n  vPosition = position.xy;\n  gl_Position = position;\n}";
    fragment = "precision highp float;\nprecision highp int;\n\nuniform float xMin, xMax, yMin, yMax;\n\nuniform " + vecType + " selectedDomainTranslate, selectedRangeTranslate;\nuniform " + matType + " selectedDomainTransformInv, selectedRangeTransform;\n\nvarying vec2 vPosition;\n\n" + glsl + "\n\nfloat lerp(float x, float dMin, float dMax, float rMin, float rMax) {\n  float ratio = (x - dMin) / (dMax - dMin);\n  return ratio * (rMax - rMin) + rMin;\n}\n\nvoid main() {\n  vec4 inputVal = vec4(\n    lerp(vPosition.x, -1., 1., xMin, xMax),\n    lerp(vPosition.y, -1., 1., yMin, yMax),\n    0.,\n    0.\n  );\n  vec4 outputVal = mainFn(inputVal);\n\n  float value = outputVal.x;\n  vec3 color;\n\n  float normvalue = clamp(0., 1., abs(value));\n  if (value > 0.) {\n    color = mix(vec3(" + config.colorMapZero + "), vec3(" + config.colorMapPositive + "), normvalue);\n  } else {\n    color = mix(vec3(" + config.colorMapZero + "), vec3(" + config.colorMapNegative + "), normvalue);\n  }\n\n  //color = vec3(value, value, value);\n\n  gl_FragColor = vec4(color, 1.);\n}";
    return createProgramFromSrc(glod, name, vertex, fragment);
  };

  drawColorMapProgram = function(glod, name, bounds) {
    var canvas;
    canvas = glod.canvas();
    glod.begin(name);
    glod.pack("quad", "position");
    glod.value("xMin", bounds.xMin);
    glod.value("xMax", bounds.xMax);
    glod.value("yMin", bounds.yMin);
    glod.value("yMax", bounds.yMax);
    addSelectedChildFnUniforms(glod);
    glod.ready().triangles().drawArrays(0, 6);
    return glod.end();
  };

  addSelectedChildFnUniforms = function(glod) {
    var domainTransformInv, domainTranslate, rangeTransform, rangeTranslate, selectedChildFn;
    selectedChildFn = UI.getSingleSelectedChildFn();
    if (!selectedChildFn) {
      return;
    }
    domainTranslate = selectedChildFn.getDomainTranslate();
    domainTransformInv = packMatrix(util.safeInv(selectedChildFn.getDomainTransform()));
    rangeTranslate = selectedChildFn.getRangeTranslate();
    rangeTransform = packMatrix(selectedChildFn.getRangeTransform());
    glod.valuev("selectedDomainTranslate", domainTranslate);
    glod.valuev("selectedDomainTransformInv", domainTransformInv);
    glod.valuev("selectedRangeTranslate", rangeTranslate);
    return glod.valuev("selectedRangeTransform", rangeTransform);
  };

  packMatrix = function(m) {
    m = numeric.transpose(m);
    return _.flatten(m);
  };

}).call(this);
}, "view/SymbolicView": function(exports, require, module) {(function() {
  var formatMatrix, formatVector, nonIdentityCell, nonIdentitySize, stringifyFn;

  R.create("SymbolicView", {
    render: function() {
      var string;
      if (!UI.showSymbolic) {
        return R.div();
      }
      string = stringifyFn(UI.selectedFn, "x", true);
      return R.div({}, string ? R.div({
        className: "Symbolic"
      }, R.span({}, stringifyFn(UI.selectedFn, "x", true))) : void 0);
    }
  });

  nonIdentityCell = function(x, y, m) {
    var identityCell;
    identityCell = x === y ? 1 : 0;
    return m[x][y] !== identityCell;
  };

  nonIdentitySize = function(m) {
    var d, found, size, x, y, _i, _j, _k, _ref;
    size = 0;
    for (d = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; d = 0 <= _ref ? ++_i : --_i) {
      found = false;
      y = d;
      for (x = _j = 0; 0 <= d ? _j <= d : _j >= d; x = 0 <= d ? ++_j : --_j) {
        if (nonIdentityCell(x, y, m)) {
          found = true;
        }
      }
      x = d;
      for (y = _k = 0; 0 <= d ? _k <= d : _k >= d; y = 0 <= d ? ++_k : --_k) {
        if (nonIdentityCell(x, y, m)) {
          found = true;
        }
      }
      if (found) {
        size = d + 1;
      }
    }
    return size;
  };

  formatMatrix = function(m) {
    var size;
    size = nonIdentitySize(m);
    if (size === 0) {
      return null;
    }
    if (size === 1) {
      return m[0][0];
    }
    return "M" + size;
  };

  formatVector = function(v) {
    var d, size, _i, _ref;
    size = 0;
    for (d = _i = 0, _ref = config.dimensions; 0 <= _ref ? _i < _ref : _i > _ref; d = 0 <= _ref ? ++_i : --_i) {
      if (v[d] !== 0) {
        size = d + 1;
      }
    }
    if (size === 0) {
      return null;
    }
    if (size === 1) {
      return v[0];
    }
    return "V" + size;
  };

  stringifyFn = function(fn, freeVariable, force) {
    var childFn, domainTransform, domainTranslate, rangeTransform, rangeTranslate, s, strings, _i, _len, _ref;
    if (freeVariable == null) {
      freeVariable = "x";
    }
    if (force == null) {
      force = false;
    }
    if (fn instanceof C.BuiltInFn) {
      if (fn.label === "Line") {
        return freeVariable;
      } else {
        return fn.label + ("( " + freeVariable + " )");
      }
    }
    if (fn instanceof C.DefinedFn && !force) {
      return fn.label + ("( " + freeVariable + " )");
    }
    if (fn instanceof C.CompoundFn) {
      if (fn.combiner === "last") {
        return stringifyFn(_.last(fn.childFns), freeVariable);
      }
      if (fn.combiner === "composition") {
        s = freeVariable;
        _ref = fn.childFns;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childFn = _ref[_i];
          s = stringifyFn(childFn, s);
        }
        return s;
      }
      if (fn.combiner === "sum") {
        strings = (function() {
          var _j, _len1, _ref1, _results;
          _ref1 = fn.childFns;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            childFn = _ref1[_j];
            _results.push(stringifyFn(childFn, freeVariable));
          }
          return _results;
        })();
        return strings.join(" + ");
      }
      if (fn.combiner === "product") {
        strings = (function() {
          var _j, _len1, _ref1, _results;
          _ref1 = fn.childFns;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            childFn = _ref1[_j];
            _results.push("(" + (stringifyFn(childFn, freeVariable)) + ")");
          }
          return _results;
        })();
        return strings.join(" * ");
      }
    }
    if (fn instanceof C.ChildFn) {
      domainTranslate = formatVector(fn.getDomainTranslate());
      domainTransform = formatMatrix(fn.getDomainTransform());
      rangeTranslate = formatVector(fn.getRangeTranslate());
      rangeTransform = formatMatrix(fn.getRangeTransform());
      s = freeVariable;
      if (domainTranslate != null) {
        s = "(" + s + " - " + domainTranslate + ")";
      }
      if (domainTransform != null) {
        s = "" + s + " / " + domainTransform;
      }
      s = stringifyFn(fn.fn, s);
      if (rangeTransform != null) {
        s = "" + s + " * " + rangeTransform;
      }
      if (rangeTranslate != null) {
        s = "" + s + " + " + rangeTranslate;
      }
      return s;
    }
  };

}).call(this);
}, "view/ThumbnailPlotLayoutView": function(exports, require, module) {(function() {
  R.create("ThumbnailPlotLayoutView", {
    propTypes: {
      plotLayout: C.PlotLayout,
      fn: C.Fn
    },
    render: function() {
      var plot;
      plot = this.plotLayout.getMainPlot();
      return R.div({
        className: "PlotContainer"
      }, R.GridView({
        plot: plot,
        isThumbnail: true
      }), R.ShaderCartesianView({
        plot: plot,
        isThumbnail: true,
        fns: [
          {
            fn: this.fn,
            color: config.color.main
          }
        ]
      }));
    }
  });

}).call(this);
}, "view/VariableView": function(exports, require, module) {(function() {
  R.create("VariableView", {
    propTypes: {
      variable: C.Variable
    },
    render: function() {
      return R.TextFieldView({
        className: "Variable",
        value: this.variable.valueString,
        onInput: this._onInput
      });
    },
    _onInput: function(newValue) {
      return Actions.setVariableValueString(this.variable, newValue);
    }
  });

}).call(this);
}, "view/plot/GridView": function(exports, require, module) {(function() {
  R.create("GridView", {
    propTypes: {
      plot: C.Plot,
      isThumbnail: Boolean
    },
    _getParams: function() {
      var canvas, dimensions, maxWorld, minWorld, params, scaleFactor, xCoord, yCoord;
      params = {};
      canvas = this.getDOMNode();
      if (this.isThumbnail) {
        scaleFactor = window.innerHeight / canvas.height;
      } else {
        scaleFactor = 1;
      }
      minWorld = this.plot.toWorld({
        x: -canvas.width * scaleFactor / 2,
        y: -canvas.height * scaleFactor / 2
      });
      maxWorld = this.plot.toWorld({
        x: canvas.width * scaleFactor / 2,
        y: canvas.height * scaleFactor / 2
      });
      dimensions = this.plot.getDimensions();
      params.xMin = numeric.dot(minWorld, dimensions[0]);
      params.yMin = numeric.dot(minWorld, dimensions[1]);
      params.xMax = numeric.dot(maxWorld, dimensions[0]);
      params.yMax = numeric.dot(maxWorld, dimensions[1]);
      params.pixelSize = this.plot.getPixelSize() * scaleFactor;
      if (scaleFactor === 1) {
        xCoord = dimensions[0].indexOf(1);
        if (xCoord < config.dimensions) {
          params.xLabelColor = config.domainLabelColor;
          params.xLabel = "d" + (xCoord + 1);
        } else {
          params.xLabelColor = config.rangeLabelColor;
          params.xLabel = "r" + (xCoord + 1 - config.dimensions);
        }
        yCoord = dimensions[1].indexOf(1);
        if (yCoord < config.dimensions) {
          params.yLabelColor = config.domainLabelColor;
          params.yLabel = "d" + (yCoord + 1);
        } else {
          params.yLabelColor = config.rangeLabelColor;
          params.yLabel = "r" + (yCoord + 1 - config.dimensions);
        }
      }
      return params;
    },
    _draw: function() {
      var canvas, ctx, didResize, params;
      didResize = this._ensureProperSize();
      params = this._getParams();
      if (!didResize && _.isEqual(params, this._lastParams)) {
        return;
      }
      this._lastParams = params;
      canvas = this.getDOMNode();
      ctx = canvas.getContext("2d");
      util.canvas.clear(ctx);
      return util.canvas.drawGrid(ctx, params);
    },
    _ensureProperSize: function() {
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
    componentDidMount: function() {
      return this._draw();
    },
    componentDidUpdate: function() {
      return this._draw();
    },
    render: function() {
      return R.canvas({});
    }
  });

}).call(this);
}, "view/plot/ShaderCartesianView": function(exports, require, module) {(function() {
  R.create("ShaderCartesianView", {
    propTypes: {
      plot: C.Plot,
      fns: Array,
      isThumbnail: Boolean
    },
    render: function() {
      return R.div({
        className: "Shader"
      });
    }
  });

}).call(this);
}, "view/plot/glod": function(exports, require, module) {'use strict';

module.exports = Glod;

function GlodError(message, data) {
  this.message = message;
  this.data = data;
}
GlodError.prototype = Object.create(Error.prototype);

function die(message, data) {
  var error = new GlodError(message || 'Glod: die', data);

  // try {
  //   throw new Error(message || 'die');
  // }
  // catch(err) {
  //   error = err;
  // }

  // var line = error.stack.split('\n')[3];
  // var at = line.indexOf('at ');
  // var origin = line.slice(at + 3, line.length);

  // error.name = 'at ' + origin;

  throw error;
}

function Glod() {
  // Prevent instantiation without new.
  if (!Glod.prototype.isPrototypeOf(this)) {
    die('Glod: instantiate with `new Glod()`')
  }

  this._canvas            = null;
  this._gl                = null;
  this._vbos              = {};
  this._fbos              = {};
  this._rbos              = {};
  this._programs          = {};
  this._textures          = {};
  this._extensions        = {};

  this._variables         = {};

  this._mode              = -1;
  this._activeProgram     = null;
  this._contextLost       = false;
  this._onContextLost     = this.onContextLost.bind(this);
  this._onContextRestored = this.onContextRestored.bind(this);
  this.loseContext        = null;
  this.restoreContext     = null;
  this._initIds           = {};
  this._allocIds          = {};
  this._versionedIds      = {};

  this._optional  = {};
  this._optionalv = {};

  this._state = 0;
}

Glod.preprocessed = {};

// this should probably be called "cache shader" or something like that
Glod.preprocess = function(source) {
  var line_re      = /\n|\r/;
  var directive_re = /^\/\/!\s*(.*)$/;

  var vertex   = [];
  var fragment = [];

  var lines = source.split(line_re);

  var name = null;

  var section = "common";

  for (var i = 0; i < lines.length; i++) {
    var line  = lines[i];
    var match = directive_re.exec(line);

    if (match) {
      var tokens = match[1].split(/\s+/);

      switch(tokens[0]) {
        case "name":     name    = tokens[1];  break;
        case "common":   section = "common";   break;
        case "vertex":   section = "vertex";   break;
        case "fragment": section = "fragment"; break;
        default: die('gl.preprocess: bad directive: ' + tokens[0]);
      }
    }

    switch(section) {
      case "common":   vertex.push(line); fragment.push(line); break;
      case "vertex":   vertex.push(line); fragment.push(''  ); break;
      case "fragment": vertex.push(''  ); fragment.push(line); break;
    }
  }

  var fragment_src = fragment.join('\n');
  var vertex_src   = vertex  .join('\n');

  name         || die('gl.preprocess: no name');
  vertex_src   || die('gl.preprocess: no vertex source: ' + name);
  fragment_src || die('gl.preprocess: no fragment source: ' + name);

  var o = {
    name:     name,
    vertex:   vertex_src,
    fragment: fragment_src
  };

  Glod.preprocessed[o.name] && die('Glod: duplicate shader name: '+ o.name);
  Glod.preprocessed[o.name] = o;
};

Glod.prototype.isInactive      = function() { return this._state === 0;     };
Glod.prototype.isPreparing     = function() { return this._state === 1;     };
Glod.prototype.isDrawing       = function() { return this._state === 2;     };
Glod.prototype.isProgramActive = function() { return !!this._activeProgram; };

Glod.prototype.startInactive  = function() { this._state = 0; return this; };
Glod.prototype.startPreparing = function() { this._state = 1; return this; };
Glod.prototype.startDrawing   = function() { this._state = 2; return this; };

Glod.prototype.assertInactive      = function() { this.isInactive()      || this.outOfPhase(0); return this; };
Glod.prototype.assertPreparing     = function() { this.isPreparing()     || this.outOfPhase(1); return this; };
Glod.prototype.assertDrawing       = function() { this.isDrawing()       || this.outOfPhase(2); return this; };
Glod.prototype.assertProgramActive = function() { this.isProgramActive() || this.outOfPhase(1); return this; };

Glod.prototype.outOfPhase = function(expected, actual) {
  function s(n) {
    return n === 0 ? 'inactive'  :
           n === 1 ? 'preparing' :
           n === 2 ? 'drawing'   :
                     'unknown (' + n + ')';
  }

  die('Glod: out of phase: expected to be ' + s(expected) + ' but was ' + s(this._state));
};


// todo: print string names and type instead of [object WebGLProgram]
// function throwOnGLError(err, funcName, args) {
//   throw WebGLDebugUtils.glEnumToString(err) + " was caused by call to: " + funcName;
// }

// function validateNoneOfTheArgsAreUndefined(functionName, args) {
//   for (var ii = 0; ii < args.length; ++ii) {
//     if (args[ii] === undefined) {
//       console.error("undefined passed to gl." + functionName + "(" +
//                     WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ")");
//     }
//   }
// }

// function logGLCall(functionName, args) {
//   console.log("gl." + functionName + "(" +
//       WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ")");
// }

// function logAndValidate(functionName, args) {
//   logGLCall(functionName, args);
//   validateNoneOfTheArgsAreUndefined (functionName, args);
// }


Glod.prototype.initContext = function() {
  var gl = this._gl;

  var supported = gl.getSupportedExtensions();

  for (var i = 0; i < supported.length; i++) {
    var name = supported[i];
    this._extensions[name] = gl.getExtension(name);
  }

  var lc = this.extension('WEBGL_lose_context');

  this.loseContext    = lc.loseContext.bind(lc);
  this.restoreContext = lc.restoreContext.bind(lc);
};

Glod.prototype.gl = function() {
  this._gl || die('Glod.gl: no gl context');
  return this._gl;
};

Glod.prototype.extension = function() {
  var l = arguments.length;
  for (var i = 0; i < l; i++) {
    var e = this._extensions[arguments[i]];
    if (e) return e;
  }
  die('Glod.extension: extension not found: ' + arguments);
};

Glod.prototype.canvas = function(canvas, options) {
  if (arguments.length === 0) {
    this.hasCanvas() || die('Glod.canvas: no canvas');
    return this._canvas;
  }

  if (this.hasCanvas()) {
    this._canvas.removeEventListener('webglcontextlost', this._onContextLost);
    this._canvas.removeEventListener('webglcontextrestored', this._onContextRestored);
  }

  this._canvas = canvas || null;

  if (canvas && !this.hasCanvas()) {
    die('Glod.canvas: bad canvas: ' + canvas);
  }

  if (this.hasCanvas()) {
    this._canvas.addEventListener('webglcontextlost', this._onContextLost);
    this._canvas.addEventListener('webglcontextrestored', this._onContextRestored);
    var opts = options || { antialias: false };
    var gl = this._canvas.getContext('webgl', options);
    gl || (gl = this._canvas.getContext('experimental-webgl', opts));
    gl || (die('Glod.canvas: failed to create context'));
    // wrap && (gl = WebGLDebugUtils.makeDebugContext(gl, throwOnGLError, logAndValidate));
    this._gl = gl;
    this.initContext();
  }
  else {
    this._gl = null;
  }

  return this;
};

Glod.prototype.hasCanvas = function() {
  return !!(this._canvas); // && this._canvas.length == 1);
};

Glod.prototype.hasVBO     = function(name) { return this._vbos    .hasOwnProperty(name); };
Glod.prototype.hasFBO     = function(name) { return this._fbos    .hasOwnProperty(name); };
Glod.prototype.hasRBO     = function(name) { return this._rbos    .hasOwnProperty(name); };
Glod.prototype.hasTexture = function(name) { return this._textures.hasOwnProperty(name); };
Glod.prototype.hasProgram = function(name) { return this._programs.hasOwnProperty(name); };

Glod.prototype.createVBO = function(name) {
  this.hasVBO(name) && die('Glod.createVBO: duplicate name: ' + name);
  this._vbos[name] = this.gl().createBuffer();
  return this;
};

Glod.prototype.createFBO = function(name) {
  this.hasFBO(name) && die('Glod.createFBO: duplicate resource name: ' + name);
  this._fbos[name] = this.gl().createFramebuffer();
  return this;
};

Glod.prototype.createRBO = function(name) {
  this.hasRBO(name) && die('Glod.createRBO: duplicate resource name: ' + name);
  this._rbos[name] = this.gl().createRenderbuffer();
  return this;
};

Glod.prototype.createTexture = function(name) {
  this.hasTexture(name) && die('Glod.createTexture: duplicate resource name: ' + name);
  this._textures[name] = this.gl().createTexture();
  return this;
};

Glod.prototype.deleteVBO = function(name) {
  var vbo = this.vbo(name);
  this.gl().deleteBuffer(vbo);
  delete this._vbos[name];
  return this;
};

var NRF = function(type, name) {
  die('Glod.' + type + ': no resource found: ' + name);
};

Glod.prototype.vbo     = function(name) { this.hasVBO(name) || NRF('vbo', name); return this._vbos[name]; };
Glod.prototype.fbo     = function(name) { this.hasFBO(name) || NRF('fbo', name); return this._fbos[name]; };
Glod.prototype.rbo     = function(name) { this.hasRBO(name) || NRF('rbo', name); return this._rbos[name]; };

Glod.prototype.program = function(name) {
  this.hasProgram(name) || NRF('program', name); return this._programs[name];
};

Glod.prototype.texture = function(name) {
  this.hasTexture(name) || NRF('texture', name); return this._textures[name];
};

Glod.prototype.onContextLost = function(e) {
  e.preventDefault();
  this._contextLost = true;
};

Glod.prototype.onContextRestored = function(e) {
  this._contextLost = false;

  var name;
  for (name in this._vbos    ) { delete this._vbos    [name]; this.createVBO    (name); }
  for (name in this._fbos    ) { delete this._fbos    [name]; this.createFBO    (name); }
  for (name in this._rbos    ) { delete this._rbos    [name]; this.createRBO    (name); }
  for (name in this._textures) { delete this._textures[name]; this.createTexture(name); }
  for (name in this._programs) { delete this._programs[name]; this.createProgram(name); }

  this.initContext();
  this._allocIds     = {};
  this._versionedIds = {};
};

Glod.prototype.createProgram = function(name) {
  name || die('bad program name: ' + name);

  var o = Glod.preprocessed[name];

  o          || die('Glod.createProgram: program not preprocessed: ' + name);
  o.name     || die('Glod.createProgram: no name specified');
  o.vertex   || die('Glod.createProgram: no vertex source');
  o.fragment || die('Glod.createProgram: no fragment source');

  name             = o.name;
  var vertex_src   = o.vertex;
  var fragment_src = o.fragment;

  this.hasProgram(name) && die('Glod.createProgram: duplicate program name: ' + name);

  var gl = this.gl();
  var program = gl.createProgram();
  this._programs[name] = program;

  function shader(type, source) {
    var s = gl.createShader(type);

    gl.shaderSource(s, source);
    gl.compileShader(s);

    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      var log = gl.getShaderInfoLog(s);
      console.log(log);
      console.log(source);
      die('Glod.createProgram: compilation failed', log);
    }

    gl.attachShader(program, s);
  }

  shader(gl.VERTEX_SHADER,   vertex_src);
  shader(gl.FRAGMENT_SHADER, fragment_src);

  for (var pass = 0; pass < 2; pass++) {
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.log(gl.getProgramInfoLog(program));
      die('Glod.createProgram: linking failed');
    }

    gl.validateProgram(program);
    if (!gl.getProgramParameter(program, gl.VALIDATE_STATUS)) {
      console.log(gl.getProgramInfoLog(program));
      die('Glod.createProgram: validation failed');
    }

    if (pass === 0) {
      var active = [];

      var activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
      for (var i = 0; i < activeAttributes; i++) {
        var info = gl.getActiveAttrib(program, i);
        var re = new RegExp('^\\s*attribute\\s+([a-z0-9A-Z_]+)\\s+' + info.name + '\\s*;', 'm');
        var sourcePosition = vertex_src.search(re);
        sourcePosition >= 0 || die('couldn\'t find active attribute "' + info.name + '" in source');
        active.push([info.name, sourcePosition]);
      }

      var layout = active.sort(function(a, b) { return a[1] > b[1]; })
                         .map (function(x   ) { return x[0];        });

      for (var i = 0; i < layout.length; i++) {
        gl.bindAttribLocation(program, i, layout[i]);
      }

      continue;
    }

    var variables = this._variables[name] = {};

    var addVariable = function(index, attrib) {
      var info = attrib ? gl.getActiveAttrib (program, i) :
                          gl.getActiveUniform(program, i);

      var name = info.name;

      variables[name] && die('Glod: duplicate variable name: ' + name);

      var location = attrib ? gl.getAttribLocation (program, name) :
                              gl.getUniformLocation(program, name) ;

      var type = info.type;

      var count = type === gl.BYTE           ? 1  :
                  type === gl.UNSIGNED_BYTE  ? 1  :
                  type === gl.SHORT          ? 1  :
                  type === gl.UNSIGNED_SHORT ? 1  :
                  type === gl.INT            ? 1  :
                  type === gl.UNSIGNED_INT   ? 1  :
                  type === gl.FLOAT          ? 1  :
                  type === gl.BOOL           ? 1  :
                  type === gl.SAMPLER_2D     ? 1  :
                  type === gl.SAMPLER_CUBE   ? 1  :

                  type === gl.  INT_VEC2     ? 2  :
                  type === gl.FLOAT_VEC2     ? 2  :
                  type === gl. BOOL_VEC2     ? 2  :

                  type === gl. INT_VEC3      ? 3  :
                  type === gl.FLOAT_VEC3     ? 3  :
                  type === gl. BOOL_VEC3     ? 3  :

                  type === gl.  INT_VEC4     ? 4  :
                  type === gl.FLOAT_VEC4     ? 4  :
                  type === gl. BOOL_VEC4     ? 4  :

                  type === gl.FLOAT_MAT2     ? 4  :
                  type === gl.FLOAT_MAT3     ? 9  :
                  type === gl.FLOAT_MAT4     ? 16 :
                  die('Glod: unknown variable type: ' + type);

      var matrix = type === gl.FLOAT_MAT2 || type === gl.FLOAT_MAT3 || type === gl.FLOAT_MAT4;

      var float = type === gl.FLOAT      ||
                  type === gl.FLOAT_VEC2 || type === gl.FLOAT_VEC3 || type === gl.FLOAT_VEC4 ||
                  type === gl.FLOAT_MAT2 || type === gl.FLOAT_MAT3 || type === gl.FLOAT_MAT4;

      variables[name] = {
        location: location,
        info:     info,
        attrib:   attrib,
        count:    count,
        float:    float,
        matrix:   matrix,
        ready:    false
      };
    }

    var activeUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
    for (var i = 0; i < activeUniforms; i++) addVariable(i, false);
    var activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
    for (var i = 0; i < activeAttributes; i++) addVariable(i, true);
  }

  var error = this.gl().getError();
  if (error !== 0) die('unexpected error: ' + error);

  return this;
};

Glod.prototype.variable = function(name) {
  this.assertProgramActive()
  var variable = this._variables[this._activeProgram][name];
  // TODO(ryan): Maybe add a flag for this? It can be useful to know when
  // variables are unused, but also annoying if you want to set them regardless.
  // variable || die('Glod.variable: variable not found: ' + name);
  return variable;
};

Glod.prototype.location = function(name) { return this.variable(name).location; };
Glod.prototype.info     = function(name) { return this.variable(name).info;     };
Glod.prototype.isAttrib = function(name) { return this.variable(name).attrib;   };

Glod.prototype.uploadCCWQuad = function() {
  var positions = new Float32Array([1, -1, 0, 1, 1, 1, 0, 1, -1, 1, 0, 1, -1, 1, 0, 1, -1, -1, 0, 1, 1, -1, 0, 1]);

  return function(name) {
    var gl = this.gl();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.vbo(name));
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
    return this;
  };
}();

Glod.prototype.uploadPlaceholderTexture = function() {
  var rgba = new Uint8Array([255, 255, 255, 255, 0, 255, 255, 255, 255, 0, 255, 255, 255, 255, 0, 255]);

  return function(name) {
    var gl  = this.gl();
    var tex = this.texture(name);

    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 2, 2, 0, gl.RGBA, gl.UNSIGNED_BYTE, rgba);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.bindTexture(gl.TEXTURE_2D, null);

    return this;
  };
}();

Glod.prototype.bindFramebuffer = function(name) {
  var fbo = name === null ? null : this.fbo(name);
  var gl = this.gl();
  gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  return this;
};


// todo:
//   use the vbo's type to determine which target to bind it to
//   support stream and dynamic draw
//   support passing a normal JS array
Glod.prototype.bufferDataStatic = function(targetName) {
  var al  = arguments.length;
  var gl  = this.gl();
  var vbo = this.vbo(targetName);

  gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

  var a;
  if (al === 2) {
    a = arguments[1];
    Array.prototype.isPrototypeOf(a) && (a = new Float32Array(a));
    gl.bufferData(gl.ARRAY_BUFFER, a, gl.STATIC_DRAW);
  }
  else if (al === 3) {
    a = arguments[1];
    Array.prototype.isPrototypeOf(a) && (a = new Float32Array(a));
    gl.bufferSubData(gl.ARRAY_BUFFER, a, arguments[2]);
  }
  else {
    die('Glod.bufferData: bad argument count: ' + al);
  }

  return this;
};

// todo:
//   support aperture base and opening
//   support scale factor
Glod.prototype.viewport = function() {
  var gl = this.gl();
  var x, y, w, h;

  var al = arguments.length;
  if (al === 4) {
    x = arguments[0];
    y = arguments[1];
    w = arguments[2];
    h = arguments[3];
  }
  else if (al === 0) {
    var canvas = this.canvas();
    x = y = 0;
    w = canvas.width;
    h = canvas.height;
  }
  else {
    die('Glod.viewport: bad argument count: ' + al);
  }

  gl.viewport(x, y, w, h);
  gl.scissor(x, y, w, h);

  return this;
}

Glod.prototype.begin = function(programName) {
  this.assertInactive().startPreparing();

  this.gl().useProgram(this.program(programName));

  this._activeProgram = programName;
  this._mode = -1;

  var variables = this._variables[programName];

  for (var name in variables) {
    variables[name].ready = false;
  }

  return this;
};

Glod.prototype.ready = function() {
  this.assertPreparing().startDrawing();

  var variables = this._variables[this._activeProgram];

  for (var name in variables) {
    var ov = this._optional[name];
    if (!variables[name].ready && ov) {
      switch(ov.length) {
        case 4: this.value(name, ov[0], ov[1], ov[2], ov[3]); break;
        case 3: this.value(name, ov[0], ov[1], ov[2]       ); break;
        case 2: this.value(name, ov[0], ov[1]              ); break;
        case 1: this.value(name, ov[0]                     ); break;
      }
    }

    variables[name].ready || die('Glod.ready: variable not ready: ' + name);
  }

  return this;
};

Glod.prototype.end = function() {
  this.assertDrawing().startInactive();
  this._activeProgram = null;
  return this;
};

Glod.prototype.manual = function() {
  this.assertProgramActive();
  for (var i = 0; i < arguments.length; i++) {
    this.variable(arguments[i]).ready = true;
  }
  return this;
};

Glod.prototype.value = function(name, a, b, c, d) {
  var v  = this.variable(name);

  // Bail if the variable does not exist.
  if (!v) return this;

  var gl = this.gl();
  var l  = arguments.length - 1;
  var loc = v.location;

  if (v.attrib) {
    l === 1 ? gl.vertexAttrib1f(loc, a         ) :
    l === 2 ? gl.vertexAttrib2f(loc, a, b      ) :
    l === 3 ? gl.vertexAttrib3f(loc, a, b, c   ) :
    l === 4 ? gl.vertexAttrib4f(loc, a, b, c, d) :
              die('Glod.value: bad length: ' + l);
  }
  else {
    var type = v.info.type;
    l === 1 ? (v.float ? gl.uniform1f(loc, a         ) : gl.uniform1i(loc, a         )) :
    l === 2 ? (v.float ? gl.uniform2f(loc, a, b      ) : gl.uniform2i(loc, a, b      )) :
    l === 3 ? (v.float ? gl.uniform3f(loc, a, b, c   ) : gl.uniform3i(loc, a, b, c   )) :
    l === 4 ? (v.float ? gl.uniform4f(loc, a, b, c, d) : gl.uniform4i(loc, a, b, c, d)) :
              die('Glod.value: bad length: ' + l);
  }
  v.ready = true;
  return this;
};

Glod.prototype.valuev = function(name, s, transpose) {
  s || die('Glod.valuev: bad vector: ' + s);

  var v = this.variable(name);

  // Bail if the variable does not exist.
  if (!v) return this;

  var gl = this.gl();
  var l = v.count;
  var loc = v.location;

  if (v.attrib) {
    l === s.length || die('Glod.valuev: bad vector length: ' + s.length);
    gl.disableVertexAttribArray(loc);
    l === 1 ? gl.vertexAttrib1fv(loc, s) :
    l === 2 ? gl.vertexAttrib2fv(loc, s) :
    l === 3 ? gl.vertexAttrib3fv(loc, s) :
    l === 4 ? gl.vertexAttrib4fv(loc, s) :
              die('Glod.valuev: bad length: ' + l);
  }
  else {
    if (v.matrix) {
      l === 4  ? gl.uniformMatrix2fv(loc, !!transpose, s) :
      l === 9  ? gl.uniformMatrix3fv(loc, !!transpose, s) :
      l === 16 ? gl.uniformMatrix4fv(loc, !!transpose, s) :
                 die('Glod.valuev: bad length: ' + l);
    }
    else {
      l === 1 ? (v.float ? gl.uniform1fv(loc, s) : gl.uniform1iv(loc, s)) :
      l === 2 ? (v.float ? gl.uniform2fv(loc, s) : gl.uniform2iv(loc, s)) :
      l === 3 ? (v.float ? gl.uniform3fv(loc, s) : gl.uniform3iv(loc, s)) :
      l === 4 ? (v.float ? gl.uniform4fv(loc, s) : gl.uniform4iv(loc, s)) :
                die('Glod.valuev: bad length: ' + l);
    }
  }

  v.ready = true;

  return this;
};

Glod.prototype.optional = function(name, a, b, c, d) {
  var l = arguments.length - 1;

  if (l === 1 && a === undefined) {
    delete this._optional[name];
    return this;
  }

  var v = this._optional[name] || [];
  this._optional[name] = v;
  v.length = l;

  switch (l) {
    case 4: v[3] = d;
    case 3: v[2] = c;
    case 2: v[1] = b;
    case 1: v[0] = a;
  }

  return this;
};

Glod.prototype.optionalv = function(name, s, transpose) {
  // WARNING: I'm not sure this actually works.
  if (arguments.length === 2 && s === undefined) {
    delete this._optionalv[name];
    return this;
  }

  var v = this._optionalv[name] || [];
  var l = s.length;
  this._optionalv[name] = v;
  v.length = s.length;
  v.TRANSPOSE = !!transpose;
  for (var i = 0; i < l; i++) {
    v[i] = s[i];
  }

  return this;
};

Glod.prototype.pack = function(vboName) {
  var vbo = this.vbo(vboName);
  var gl  = this.gl();

  gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

  arguments.length < 2 && die('Glod.pack: no attribute provided');

  var stride = 0;
  var counts = [];
  var vars = [];
  for (var i = 1; i < arguments.length; i++) {
    var name = arguments[i];
    var v = this.variable(name);
    v.attrib || die('Glod.pack: tried to pack uniform: ' + name);
    v.ready  && die('Glod.pack: variable already ready: ' + name);
    var count = v.count;
    stride += count;
    counts.push(count);
    vars.push(v);
  }

  var offset = 0;
  for (var i = 1; i < arguments.length; i++) {
    var name = arguments[i];
    var v = vars[i - 1];
    var loc = v.location;
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, v.count, gl.FLOAT, false, stride * 4, offset * 4);
    offset += v.count;
    v.ready = true;
  }

  return this;
};

Glod.prototype.primitive = function(mode) {
  (mode >= 0 && mode <= 6) || die('Glod.mode: bad mode: ' + mode);
  this._mode = mode
  return this;
};

Glod.prototype.points        = function() { this._mode = this._gl.POINTS;         return this; };
Glod.prototype.lines         = function() { this._mode = this._gl.LINES;          return this; };
Glod.prototype.lineLoop      = function() { this._mode = this._gl.LINE_LOOP;      return this; };
Glod.prototype.lineStrip     = function() { this._mode = this._gl.LINE_STRIP;     return this; };
Glod.prototype.triangles     = function() { this._mode = this._gl.TRIANGLES;      return this; };
Glod.prototype.triangleStrip = function() { this._mode = this._gl.TRIANGLE_STRIP; return this; };
Glod.prototype.triangleFan   = function() { this._mode = this._gl.TRIANGLE_FAN;   return this; };

Glod.prototype.drawArrays = function(first, count) {
  var mode = this._mode;
  (mode >= 0 && mode <= 6) || die('Glod.drawArrays: mode not set');
  var gl = this.gl();
  gl.drawArrays(mode, first, count);
  return this;
};

Glod.prototype.clearColor   = function(r, g, b, a) { this.gl().clearColor  (r, g, b, a); return this; };
Glod.prototype.clearDepth   = function(d         ) { this.gl().clearDepth  (d         ); return this; };
Glod.prototype.clearStencil = function(s         ) { this.gl().clearStencil(s         ); return this; };

Glod.prototype.clearColorv = function(s) {
  return this.clearColor(s[0], s[1], s[2], s[3]);
};

Glod.prototype.clear = function(color, depth, stencil) {
  var gl = this.gl();

  var clearBits = 0;
  color   && (clearBits |= gl.  COLOR_BUFFER_BIT);
  depth   && (clearBits |= gl.  DEPTH_BUFFER_BIT);
  stencil && (clearBits |= gl.STENCIL_BUFFER_BIT);

  clearBits && gl.clear(clearBits);
  return this;
};

Glod.prototype.bindArrayBuffer = function(name) {
  var gl = this._gl;
  gl.bindBuffer(gl.ARRAY_BUFFER, this.vbo(name));
  return this;
};

Glod.prototype.bindElementBuffer = function(name) {
  var gl = this._gl;
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.vbo(name));
  return this;
};

Glod.prototype.bindTexture2D = function(name) {
  var texture = name === null ? null : this.texture(name);
  var gl = this._gl;
  gl.bindTexture(gl.TEXTURE_2D, texture);
  return this;
};

Glod.prototype.activeTexture = function(unit) {
  var gl = this._gl;
  gl.activeTexture(gl.TEXTURE0 + unit);
  return this;
};

Glod.prototype.init = function(id, f) {
  this._initIds[id] || f();
  this._initIds[id] = true;
  return this;
};

Glod.prototype.alloc = function(id, f) {
  this._allocIds[id] || f();
  this._allocIds[id] = true;
  return this;
};

Glod.prototype.allocv = function(id, v, f) {
  if (this._versionedIds[id] !== v) {
    this._versionedIds[id] = v;
    f();
  }
  return this;
};
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
      return this._isDirty = false;
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
