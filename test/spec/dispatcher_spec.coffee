define [
  'underscore'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/dispatcher'
], (_, mediator, Controller, Dispatcher) ->
  'use strict'
  describe 'Dispatcher', ->
    #console.debug 'Dispatcher spec'

    # Initialize shared variables
    dispatcher = params = null

    # Unique ID counter for creating params objects
    paramsId = 0

    # Fake route objects, walk like a route and swim like a route

    route1 = controller: 'test1', action: 'show'
    route2 = controller: 'test2', action: 'show'

    redirectToURLRoute = controller: 'test1', action: 'redirectToURL'
    redirectToControllerRoute = controller: 'test1', action: 'redirectToController'

    # Reset helpers

    refreshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = changeURL: false, id: paramsId++

    # Define test controllers
    class Test1Controller extends Controller

      historyURL: (params) ->
        #console.debug 'Test1Controller#historyURL'
        'test1/' + (params.id or '')

      initialize: (params, oldControllerName) ->
        #console.debug 'Test1Controller#initialize', params, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'Test1Controller#show', params, oldControllerName

      redirectToURL: (params, oldControllerName) ->
        @redirectTo '/test2/123'

      redirectToController: (params, oldControllerName) ->
        @redirectTo 'test2', 'show', params

      dispose: (params, newControllerName) ->
        #console.debug 'Test1Controller#dispose'
        super

    class Test2Controller extends Controller

      historyURL: (params) ->
        #console.debug 'Test2Controller#historyURL'
        'test2/' + (params.id or '')

      initialize: (params, oldControllerName) ->
        #console.debug 'Test2Controller#initialize', params, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'Test2Controller#show', params, oldControllerName

      dispose: (params, newControllerName) ->
        #console.debug 'Test2Controller#dispose'
        super

    # Define a test controller AMD modules
    define 'controllers/test1_controller', -> Test1Controller
    define 'controllers/test2_controller', -> Test2Controller

    beforeEach refreshParams

    it 'should initialize', ->
      dispatcher = new Dispatcher()

    it 'should dispatch routes to controller actions', ->
      proto = Test1Controller.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      mediator.publish 'matchRoute', route1, params

      expect(initialize).toHaveBeenCalledWith params, null
      expect(action).toHaveBeenCalledWith params, null
      expect(historyURL).toHaveBeenCalledWith params

    it 'should not start the same controller if params match', ->
      mediator.publish 'matchRoute', route1, params

      proto = Test1Controller.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      mediator.publish 'matchRoute', route1, params

      expect(initialize).not.toHaveBeenCalled()
      expect(action).not.toHaveBeenCalled()
      expect(historyURL).not.toHaveBeenCalled()

    it 'should start the same controller if params differ', ->
      mediator.publish 'matchRoute', route1, params

      proto = Test1Controller.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      refreshParams()
      mediator.publish 'matchRoute', route1, params

      expect(initialize).toHaveBeenCalledWith params, 'test1'
      expect(action).toHaveBeenCalledWith params, 'test1'
      expect(historyURL).toHaveBeenCalledWith params

    it 'should start the same controller if forced', ->
      mediator.publish 'matchRoute', route1, params

      proto = Test1Controller.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      params.forceStartup = true
      mediator.publish 'matchRoute', route1, params

      expect(initialize).toHaveBeenCalledWith params, 'test1'
      expect(action).toHaveBeenCalledWith params, 'test1'
      expect(historyURL).toHaveBeenCalledWith params

    it 'should save the controller, action, params and url', ->
      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params

      d = dispatcher
      expect(d.previousControllerName).to.equal 'test1'
      expect(d.currentControllerName).to.equal 'test2'
      expect(d.currentController).to.be.an.instanceof Test2Controller
      expect(d.currentAction).to.equal 'show'
      expect(d.currentParams).to.equal params
      expect(d.url).to.equal "test2/#{params.id}"

    it 'should dispose inactive controllers and fire beforeControllerDispose events', ->
      proto = Test2Controller.prototype
      dispose = spyOn(proto, 'dispose').andCallThrough()

      # Route back to Test1Controller
      mediator.publish 'matchRoute', route1, params

      expect(dispose).toHaveBeenCalledWith params, 'test1'

    it 'should fire beforeControllerDispose events', ->
      beforeControllerDispose = jasmine.createSpy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params

      expect(beforeControllerDispose).toHaveBeenCalled()
      passedController = beforeControllerDispose.mostRecentCall.args[0]
      expect(passedController).to.be.an.instanceof Test1Controller
      expect(passedController.disposed).to.be.ok

      mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

    it 'should publish startupController events', ->
      startupController = jasmine.createSpy()
      mediator.subscribe 'startupController', startupController

      # Route back to Test1Controller
      mediator.publish 'matchRoute', route1, params

      passedEvent = startupController.mostRecentCall.args[0]
      expect(passedEvent).to.be.an 'object'
      expect(passedEvent.controller).to.be.an.instanceof Test1Controller
      expect(passedEvent.controllerName).to.equal 'test1'
      expect(passedEvent.params).to.equal params
      expect(passedEvent.previousControllerName).to.equal 'test2'

      mediator.unsubscribe 'startupController', startupController

    it 'should listen to !startupController events', ->
      proto = Test1Controller.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      mediator.publish '!startupController', 'test1', 'show', params

      expect(initialize).toHaveBeenCalledWith params, 'test1'
      expect(action).toHaveBeenCalledWith params, 'test1'
      expect(historyURL).toHaveBeenCalledWith params

      d = dispatcher
      expect(d.previousControllerName).to.equal 'test1'
      expect(d.currentControllerName).to.equal 'test1'
      expect(d.currentController).to.be.an.instanceof Test1Controller
      expect(d.currentAction).to.equal 'show'
      expect(d.currentParams).to.equal params
      expect(d.url).to.equal "test1/#{params.id}"

    it 'should support redirection to a URL', ->
      proto = Test1Controller.prototype
      action = spyOn(proto, 'redirectToURL').andCallThrough()

      startupController = jasmine.createSpy()
      mediator.subscribe 'startupController', startupController

      mediator.publish 'matchRoute', redirectToURLRoute, params

      expect(action).toHaveBeenCalledWith(params, 'test1')

      # Don’t expect that the new controller was called
      # because we’re not testing the router. Just test
      # if execution stopped (e.g. Test1Controller is still active)
      d = dispatcher
      expect(d.previousControllerName).to.equal 'test1'
      expect(d.currentControllerName).to.equal 'test1'
      expect(d.currentController).to.be.an.instanceof Test1Controller
      expect(d.currentAction).to.equal 'show'
      expect(d.currentParams).not.to.equal params
      expect(d.url).not.to.equal "test1/#{params.id}"

      expect(startupController).not.toHaveBeenCalled()

      mediator.unsubscribe 'startupController', startupController

    it 'should support redirection to a controller action', ->
      proto = Test1Controller.prototype
      redirectAction = spyOn(proto, 'redirectToController').andCallThrough()

      proto = Test2Controller.prototype
      targetAction = spyOn(proto, 'show').andCallThrough()

      startupController = jasmine.createSpy()
      mediator.subscribe 'startupController', startupController

      # Redirects from Test1Controller to Test2Controller
      mediator.publish 'matchRoute', redirectToControllerRoute, params

      expect(redirectAction).toHaveBeenCalledWith params, 'test1'
      expect(targetAction).toHaveBeenCalledWith params, 'test1'

      # Expect that the new controller was called because this does not require
      # the router but the controller to fire a !startupController event
      d = dispatcher
      expect(d.previousControllerName).to.equal 'test1'
      expect(d.currentControllerName).to.equal 'test2'
      expect(d.currentController).to.be.an.instanceof Test2Controller
      expect(d.currentAction).to.equal 'show'
      expect(d.currentParams).to.equal params
      expect(d.url).to.equal "test2/#{params.id}"

      # startupController event was only triggered once
      expect(startupController).toHaveBeenCalled()
      expect(startupController.callCount).to.equal 1

      mediator.unsubscribe 'startupController', startupController

    it 'should dispose itself correctly', ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      proto = Test1Controller.prototype
      initialize = spyOn(proto, 'initialize').andCallThrough()
      mediator.publish 'matchRoute', route1, params
      expect(initialize).not.toHaveBeenCalled()

      expect(dispatcher.disposed).to.be.ok
      if Object.isFrozen
        expect(Object.isFrozen(dispatcher)).to.be.ok

    it 'should be extendable', ->
      expect(Dispatcher.extend).to.be.a 'function'

      DerivedDispatcher = Dispatcher.extend()
      derivedDispatcher = new DerivedDispatcher()
      expect(derivedDispatcher).to.be.an.instanceof Dispatcher

      derivedDispatcher.dispose()
