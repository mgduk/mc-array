
# mocking mc.Client
class MockMcClient

    constructor: ->
        @data = {}

    append: (key, value, callback) ->
        return callback null, 'NOT_STORED' unless @data[key]
        @data[key] += value
        callback null, 'STORED' if callback

    set: (key, value, callback) ->
        @data[key] = value
        callback null, 'STORED' if callback

    gets: (key, callback) ->
        o = {}
        o[key] = cas: 'cas', val: @data[key]
        callback null, o if callback

    cas: (key, cas, value, callback) ->
        @set key, value, callback

module.exports = MockMcClient
