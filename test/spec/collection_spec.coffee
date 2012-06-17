define [
  'underscore'
  'chaplin/mediator'
  'chaplin/models/collection'
  'chaplin/lib/subscriber'
  'chaplin/lib/sync_machine'
], (_, mediator, Collection, Subscriber, SyncMachine) ->
  'use strict'

  describe 'Collection', ->
    #console.debug 'Collection spec'

    collection = null

    beforeEach ->
      collection = new Collection

    afterEach ->
      collection.dispose()

    expectOrder = (order) ->
      for id, index in order
        expect(collection.at(index).id).to.equal id

    it 'should mixin a Subscriber', ->
      for own name, value of Subscriber
        expect(collection[name]).to.equal Subscriber[name]

    it 'should initialize a Deferred', ->
      expect(collection.initDeferred).to.be.a 'function'
      collection.initDeferred()
      for method in ['done', 'fail', 'progress', 'state', 'promise']
        expect(typeof collection[method]).to.equal 'function'
      expect(collection.state()).to.equal 'pending'

    it 'should initialize a SyncMachine', ->
      expect(collection.initSyncMachine).to.be.a 'function'
      collection.initSyncMachine()
      for own name, value of SyncMachine
        if typeof value is 'function'
          expect(collection[name]).to.equal value
      expect(collection.syncState()).to.equal 'unsynced'

    it 'should add models atomically', ->
      expect(collection.addAtomic).to.be.a 'function'

      collection.reset ({id: i} for i in [0..2])

      addSpy = jasmine.createSpy()
      collection.on 'add', addSpy
      resetSpy = jasmine.createSpy()
      collection.on 'reset', resetSpy

      collection.addAtomic ({id: i} for i in [3..5])
      expectOrder [0, 1, 2, 3, 4, 5]

      expect(addSpy).not.toHaveBeenCalled()
      expect(resetSpy).toHaveBeenCalled()

    it 'should add models atomically at a specific position', ->
      collection.reset ({id: i} for i in [0..2])

      addSpy = jasmine.createSpy()
      collection.on 'add', addSpy
      resetSpy = jasmine.createSpy()
      collection.on 'reset', resetSpy

      collection.addAtomic ({id: i} for i in [3..5]), at: 1
      expectOrder [0, 3, 4, 5, 1, 2]

      expect(addSpy).not.toHaveBeenCalled()
      expect(resetSpy).toHaveBeenCalled()

    it 'should update models', ->
      expect(collection.update).to.be.a 'function'

      collection.reset ({id: i} for i in [0..5])

      addSpy = jasmine.createSpy()
      collection.on 'add', addSpy
      removeSpy = jasmine.createSpy()
      collection.on 'remove', removeSpy
      resetSpy = jasmine.createSpy()
      collection.on 'reset', resetSpy

      newOrder = [1, 3, 5, 7, 9, 11]
      collection.update ({id: i} for i in newOrder)
      expectOrder newOrder

      expect(addSpy.callCount).to.equal 3
      expect(removeSpy.callCount).to.equal 3
      expect(resetSpy).not.toHaveBeenCalled()

    it 'should update models deeply', ->
      collection.reset ({id: i, old1: true, old2: false} for i in [0..5])
      newOrder = [1, 3, 5, 7, 9, 11]
      models = ({id: i, old2: true, new: true} for i in newOrder)

      collection.update models, deep: true
      expectOrder newOrder

      for id in [1, 3, 5]
        model = collection.get id
        expect(model.get('old1')).to.be.ok
        expect(model.get('old2')).to.be.ok
        expect(model.get('new')).to.be.ok
      for id in [7, 9, 11]
        model = collection.get id
        expect(model.get('old1')).to.equal undefined
        expect(model.get('old2')).to.be.ok
        expect(model.get('new')).to.be.ok

    it 'should dispose itself correctly', ->
      expect(collection.dispose).to.be.a 'function'
      collection.dispose()

      expect(collection.length).to.equal 0

      expect(collection.disposed).to.be.ok
      if Object.isFrozen
        expect(Object.isFrozen(collection)).to.be.ok

    it 'should fire a dispose event', ->
      disposeSpy = jasmine.createSpy()
      collection.on 'dispose', disposeSpy

      collection.dispose()

      expect(disposeSpy).toHaveBeenCalled()

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = jasmine.createSpy()
      collection.subscribeEvent 'foo', pubSubSpy

      collection.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).not.toHaveBeenCalled()

    it 'should remove all event handlers from itself', ->
      collectionBindSpy = jasmine.createSpy()
      collection.on 'foo', collectionBindSpy

      collection.dispose()

      collection.trigger 'foo'
      expect(collectionBindSpy).not.toHaveBeenCalled()

    it 'should reject the Deferred on disposal', ->
      collection.initDeferred()
      failSpy = jasmine.createSpy()
      collection.fail failSpy

      collection.dispose()

      expect(collection.state()).to.equal 'rejected'
      expect(failSpy).toHaveBeenCalled()

    it 'should remove instance properties', ->
      collection.dispose()

      for prop in ['model', 'models', '_byId', '_byCid']
        expect(_(collection).has prop).to.not.be.ok
