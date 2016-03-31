Promise = require 'bluebird'

# This module allows arrays of string values to be stored in memcached
#
# Features include
#  - values can be added and removed from the array with a single append call
#  - doesn't require full set of values to be fetched to add or remove values
#  - no locks are required to add/remove
#  - automatically garbage collects to compact the stored data when required
#
# adapted from a post by Dustin Sallings (@dustin on GitHub)
# http://dustin.sallings.org/2011/02/17/memcached-set.html
#
class mc_array

    # the number of redundant values to allow before the array
    # is compacted
    GARBAGE_THRESHOLD: 50

    # using characters that aren't in base64
    ADD_OP: '*'
    REMOVE_OP: '-'

    # Requires an instance of mc.Client from the 'mc' memcache package
    # key is the string key under which data is stored in memcache
    constructor: (@cache, @key) ->

    # Encode an array of values to modify the set.
    #
    # encodeSet ['a', 'b', 'c']
    # => '*a *b *c '
    #
    encodeSet: (values, op = @ADD_OP) ->
        values = for v in values when v
            # JSON encode then base64 encode
            b = new Buffer JSON.stringify v
            op + b.toString('base64') + ' '
        values.join ''

    # Decode a cached string into an array of strings
    #
    # Also returns a garbage count indicating how many items in the
    # stored data are now redundant.
    #
    # decodeSet '*a *b *c -b -x'
    # => { garbage: 2, values: ['a', 'c'] }
    #
    decodeSet: (s) ->
        values = []
        garbage = 0
        if s and typeof s is 'string'
            for v in s.split ' ' when v isnt ''
                op = v[0]
                b = new Buffer v.substring(1), 'base64'
                value = JSON.parse b.toString()
                if op is @ADD_OP
                    values.push value
                else if op is @REMOVE_OP
                    position = values.indexOf value
                    # remove value from array
                    values.splice position, 1 unless position is -1
                    garbage++

        garbage: garbage,
        values: values

    # returns a promise that resolves to a boolean indicating store success
    modify: (op, values) ->
        return new Promise (resolve, reject) =>
            encoded = @encodeSet values, op
            @cache.append @key, encoded, (err, status) =>
                return reject err if err
                if status is 'STORED'
                    return resolve true
                else
                    # item removed from empty value is successful as
                    # the item is not there
                    return resolve true unless op is @ADD_OP
                    # If we can't append, and we're adding to the set,
                    # we are trying to create the index, so do that.
                    @cache.set @key, encoded, (err, status) ->
                        return reject err if err
                        return resolve status is 'STORED'

    # Add the given value or array of values to the given array
    #
    # string|array values
    # Returns a promise that resolves to a success boolean
    add: (values) ->
        values = [values] unless Array.isArray values
        @modify @ADD_OP, values

    # Remove the given value or array of values from the given array
    #
    # string|array values
    # Returns a promise that resolves to a success boolean
    remove: (values) ->
        values = [values] unless Array.isArray values
        @modify @REMOVE_OP, values

    # Retrieve the current values from the set.
    # This may trigger compacting if you ask it to or the encoding is
    # too dirty.
    #
    # Returns a promise that resolves to an array of strings
    get: (forceCompacting = false) ->
        return new Promise (resolve, reject) =>
            @cache.gets @key, (err, response) =>
                return reject err if err
                return resolve [] unless response?[@key]
                # 'cas' is 'check and store' ID, to ensure
                # we only write back if no other client has written
                # to this key in the meantime
                {cas, val: data} = response[@key]

                {garbage, values} = @decodeSet data

                if forceCompacting or garbage > @GARBAGE_THRESHOLD
                    compacted = @encodeSet values
                    # hit and hope — worst case is that the value remains
                    # uncompacted until next time
                    @cache.cas @key, cas, compacted

                resolve values

module.exports = mc_array
