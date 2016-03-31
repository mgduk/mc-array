`mc-array` makes it easy to store an array of string and non-string values in [memcached](https://memcached.org/). Great for caching to achieve high performance in your app.

Adds support for storing and retrieving arrays of values into a single key in memcached. Values can be strings, arrays, objects, whatever.

Adding and removing items from the array only requires a single `append` call to memcached — no locking, no fetching the whole array, no waiting required.

Uses the excellent [`mc`](https://www.npmjs.com/package/mc) package by [bluejack](https://www.npmjs.com/~bluejack) to communicate with memcached.

## Requirements
 - memcached installed on your server — e.g. `yum install memcached`
 - [bluejack's `mc`](https://www.npmjs.com/package/mc) — `npm install --save mc`

## Usage

```js
var mc = require('mc');
var mc_array = require('mc-array');
var cache = new mc.Client();

var colours = new mc_array(cache, 'colours');

colours.add('blue');
colours.add(['red', 'green']);

colours.get().then(function(c) { console.log(c); });
// => ['blue', 'red', 'green']

colours.remove('red');
colours.add({"duck-egg": "green", "sunset": "yellow"});

colours.get().then(function(c) { console.log(c); });
// => ['blue', 'green', {"duck-egg": "green", "sunset": "yellow"}]

colours.add([['brown', 'beige', 'swiss milk chocolate']]);
colours.get().then(function(c) { console.log(c); });
// => [
//     'blue',
//     'green',
//     {"duck-egg": "green", "sunset": "yellow"},
//     ['brown', 'beige', 'swiss milk chocolate']
// ]
```

See tests for more usage examples.

## Tests
```
npm install
npm tests
```

## Licence

```text
MIT License

Copyright (c) 2016 Matt Dolan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Credits

Adapted from [a post](http://dustin.sallings.org/2011/02/17/memcached-set.html) by [Dustin Sallings](https://github.com/dustin) with thanks!
