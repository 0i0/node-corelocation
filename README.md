## node-corelocation

Get your computer's location, via the CoreLocation framework. Only
compatible with OSX.

```js
var cl = require('corelocation');

cl.getLocation(); // [longitude, latitude]
```

Mostly a nodejs port of [lost](https://github.com/evanphx/lost) for Ruby.
