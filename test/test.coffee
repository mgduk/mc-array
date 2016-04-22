sinon = require 'sinon'
chai = require 'chai'
sinonChai = require 'sinon-chai'
chaiAsPromised = require 'chai-as-promised'
chai.should()
chai.use sinonChai
chai.use chaiAsPromised

mc_client = require './mocks/mock-mc-client'
mc_array = require '../src/mc-array'

cache = null
colours = null

describe 'mc-array', ->
    beforeEach ->
        cache = new mc_client()
        colours = new mc_array cache, 'colours'

    describe 'encodeSet', ->
        it "encodes ['blue'] as '*Ymx1ZQ== '", ->
            sinon.spy colours, 'encodeSet'
            colours.encodeSet ['blue']
            colours.encodeSet.should.have.returned '*ImJsdWUi '

        it "encodes ['blue', 'red'] as '*ImJsdWUi *InJlZCI= '", ->
            sinon.spy colours, 'encodeSet'
            colours.encodeSet ['blue', 'red']
            colours.encodeSet.should.have.returned '*ImJsdWUi *InJlZCI= '

        it "correctly encodes removed items", ->
            sinon.spy colours, 'encodeSet'
            colours.encodeSet ['blue', 'red'], '-'
            colours.encodeSet.should.have.returned '-ImJsdWUi -InJlZCI= '

    describe 'decodeSet', ->
        it "correctly decodes compacted items", ->
            sinon.spy colours, 'decodeSet'
            colours.decodeSet('*ImJsdWUi *InJlZCI= *ImdyZWVuIg== ')
            colours.decodeSet.should.have.returned {
                garbage: 0,
                values: ['blue', 'red', 'green']
            }

        it "correctly decodes mixed items", ->
            sinon.spy colours, 'decodeSet'
            colours.decodeSet('*ImJsdWUi *InJlZCI= *ImdyZWVuIg== -InJlZCI= -ImJsdWUi ')
            colours.decodeSet.should.have.returned {
                garbage: 2,
                values: ['green']
            }

        it "correctly decodes fully redundant items", ->
            sinon.spy colours, 'decodeSet'
            colours.decodeSet('*ImJsdWUi *InJlZCI= *ImdyZWVuIg== -InJlZCI= -ImJsdWUi -ImdyZWVuIg== ')
            colours.decodeSet.should.have.returned {
                garbage: 3,
                values: []
            }

        it "ignores a removed, non-added item", ->
            sinon.spy colours, 'decodeSet'
            colours.decodeSet('*ImJsdWUi -ImJsdWUi -ImNhcnJvdHMi ')
            colours.decodeSet.should.have.returned {
                garbage: 2,
                values: []
            }

    describe 'add()', ->
        it 'calls encodeSet with the correct args for an array of one', ->
            sinon.spy colours, 'encodeSet'
            colours.add ['blue']
            colours.encodeSet.should.have.been.calledWith ['blue'], '*'

        it 'calls encodeSet with the correct args for an array of multiple', ->
            sinon.spy colours, 'encodeSet'
            colours.add ['blue', 'red', 'mauve']
            colours.encodeSet.should.have.been.calledWith ['blue', 'red', 'mauve'], '*'

        it 'calls encodeSet with the correct args for a string', ->
            sinon.spy colours, 'encodeSet'
            colours.add 'blue'
            colours.encodeSet.should.have.been.calledWith ['blue'], '*'

        it 'resolves to true when successfully adding an item', ->
            colours.add('blue').should.eventually.equal true

        it 'calls cache.append() with correct args for a single string', ->
            sinon.spy cache, 'append'
            colours.add 'blue'
            cache.append.should.have.been.calledWith 'colours', '*ImJsdWUi '

        it 'calls cache.set() for an empty set', ->
            sinon.spy cache, 'set'
            colours.add 'blue'
            .then () ->
                cache.set.should.have.been.calledWith 'colours', '*ImJsdWUi '

        it 'does not call cache.set() for an non-empty set', ->
            colours.add 'blue'
            sinon.spy cache, 'set'
            colours.add 'red'
            cache.set.should.have.not.been.called

        it 'calls cache.append for every add', ->
            sinon.spy cache, 'append'
            colours.add 'red'
            colours.add ['blue', 'green']
            colours.remove 'blue'
            cache.append.should.have.been.calledThrice

        it 'stores an object as a base64 encoded JSON', ->
            sinon.spy cache, 'append'
            colours.add {'foo': 'bar baz'}
            cache.append.should.have.been.calledWith 'colours', '*eyJmb28iOiJiYXIgYmF6In0= '

        it 'stores an array in an array as a base64 encoded JSON', ->
            sinon.spy cache, 'append'
            colours.add [['sheep', 'horse', 'cow']]
            cache.append.should.have.been.calledWith 'colours', '*WyJzaGVlcCIsImhvcnNlIiwiY293Il0= '

    describe 'remove()', ->
        it 'calls encodeSet with the correct args for an array of one', ->
            sinon.spy colours, 'encodeSet'
            colours.remove ['blue']
            colours.encodeSet.should.have.been.calledWith ['blue'], '-'

        it 'calls encodeSet with the correct args for an array of multiple', ->
            sinon.spy colours, 'encodeSet'
            colours.remove ['blue', 'red', 'mauve']
            colours.encodeSet.should.have.been.calledWith ['blue', 'red', 'mauve'], '-'

        it 'calls encodeSet with the correct args for a string', ->
            sinon.spy colours, 'encodeSet'
            colours.remove 'blue'
            colours.encodeSet.should.have.been.calledWith ['blue'], '-'

        it 'resolves to true when successfully removing an item', ->
            colours.remove('blue').should.eventually.equal true

        it 'calls cache.append() with correct args for a single string', ->
            sinon.spy cache, 'append'
            colours.remove 'blue'
            cache.append.should.have.been.calledWith 'colours', '-ImJsdWUi '

        it 'does not call cache.set() for an empty set', ->
            sinon.spy cache, 'set'
            colours.remove 'blue'
            cache.set.should.have.not.been.called

        it 'does not call cache.set() for an non-empty set', ->
            colours.remove 'blue'
            sinon.spy cache, 'set'
            colours.remove 'red'
            cache.set.should.have.not.been.called

        it 'calls cache.append for every remove', ->
            sinon.spy cache, 'append'
            colours.remove 'red'
            colours.remove ['blue', 'green']
            colours.remove 'blue'
            cache.append.should.have.been.calledThrice

    describe 'get()', ->
        it 'returns an empty array when no items have been added', ->
            colours.get().should.eventually.eql []

        it 'retrieves the correct items back from mixed adds/removes', ->
            colours.add 'red'
            .then -> colours.add ['blue', 'green']
            .then -> colours.remove 'blue'
            .then ->
                colours.get().should.eventually.eql ['red', 'green']

        it 're-encodes the values when the number of items exceeds GARBAGE_THRESHOLD', ->
            colours.GARBAGE_THRESHOLD = 5
            colours.add ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'voilet']
            .then -> colours.remove ['red', 'orange', 'yellow', 'green', 'blue', 'indigo']
            .then ->
                sinon.spy colours, 'encodeSet'
                colours.get()
                .then ->
                    colours.encodeSet.should.have.been.calledWith ['voilet']

        it 're-encodes the values if forceCompacting is true', ->
            sinon.spy colours, 'encodeSet'
            colours.add ['red']
            .then ->
                colours.get true
                colours.encodeSet.should.have.been.calledWith ['red']

        it 'calls cache.cas when the data has been compacted', ->
            sinon.spy cache, 'cas'
            colours.add ['red']
            .then -> colours.get true
            .then ->
                cache.cas.should.have.been.calledWith 'colours', 'cas', '*InJlZCI= '

        it 'gets an object back correctly', ->
            o = {foo: 'bar', baz: 12}
            colours.add o
            .then ->
                colours.get().should.eventually.eql [o]

        it 'gets an array of mixed values back correctly', ->
            a = [{foo: 'bar', baz: 12}, {56: 90}, 'sponge']
            o = {"fee": "fi", "fo": ["fum"]}
            s1 = 'whatever'
            s2 = '"whatever"'
            colours.add [a, s2, s1, o]
            .then ->
                colours.get().should.eventually.eql [a, s2, s1, o]

        it 'gets an already JSON encoded string back correctly', ->
            s = '"my value"'
            colours.add [s]
            .then ->
                colours.get().should.eventually.eql [s]
