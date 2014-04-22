StyleSheetList.prototype.reload_interval = 1000; // 1 second

CSSStyleSheet.prototype.reload = function reload(){
  // Reload one stylesheet
  // usage: document.styleSheets[0].reload()
  // return: URI of stylesheet if it could be reloaded, overwise undefined
  if (this.href) {
    var href = this.href;
    var i = href.indexOf('?'),
        last_reload = 'last_reload=' + (new Date).getTime();
    if (i < 0) {
      href += '?' + last_reload;
    } else if (href.indexOf('last_reload=', i) < 0) {
      href += '&' + last_reload;
    } else {
      href = href.replace(/last_reload=\d+/, last_reload);
    }
    return this.ownerNode.href = href;
  }
};

StyleSheetList.prototype.reload = function reload(){
  // Reload all stylesheets
  // usage: document.styleSheets.reload()
  for (var i=0; i<this.length; i++) {
    this[i].reload()
  }
};

StyleSheetList.prototype.start_autoreload = function start_autoreload(miliseconds /*Number*/){
  // usage: document.styleSheets.start_autoreload()
  if (!start_autoreload.running) {
    var styles = this;
    start_autoreload.running = setInterval(function reloading(){
      styles.reload();
    }, miliseconds || this.reload_interval);
  }
  return start_autoreload.running;
};

StyleSheetList.prototype.stop_autoreload = function stop_autoreload(){
  // usage: document.styleSheets.stop_autoreload()
  clearInterval(this.start_autoreload.running);
  this.start_autoreload.running = null;
};

StyleSheetList.prototype.toggle_autoreload = function toggle_autoreload(){
  // usage: document.styleSheets.toggle_autoreload()
  return this.start_autoreload.running ? this.stop_autoreload() : this.start_autoreload();
};