# Shadershop

http://tobyschachman.com/Shadershop/

Shadershop is an interface for programming GPU shaders in the mode of a direct manipulation image editor like Photoshop. It is an experiment in leveraging the programmer’s spatial reasoning the way that coding today leverages the programmer’s symbolic reasoning.

## Demo

http://www.cdglabs.org/Shadershop/

<a href="http://tobyschachman.com/Shadershop/instructions.png"><img src="http://tobyschachman.com/Shadershop/instructions.png"></a>

### Keyboard Commands

* Ctrl-R to reset. Shadershop will auto-save.
* Ctrl-1 through Ctrl-4 to load examples from the videos.
* Shift-click will also work to select multiple functions.

## Build Instructions

Install [node.js](http://nodejs.org/) and [coffeescript](http://coffeescript.org/).

Run `npm install` in this directory to install the development dependencies.

Run `coffee build.coffee` to build. It will compile the files in `src` into `compiled/app.js` and `compiled/app.css`. It will also automatically watch for changes in `src` files and recompile as necessary.

Now just open `index.html`. You can also open `dev.html` which uses the development version of React and will give you better console warnings.
