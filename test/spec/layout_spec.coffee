define [
  'jquery'
  'chaplin/mediator'
  'chaplin/lib/router'
  'chaplin/controllers/controller'
  'chaplin/views/layout'
  'chaplin/views/view'
], ($, mediator, Router, Controller, Layout, View) ->
  'use strict'

  describe 'Layout', ->
    # Initialize shared variables
    layout = testController = startupControllerContext = router = null

    beforeEach ->
      # Create the layout
      layout = new Layout title: 'Test Site Title'

      # Create a test controller
      testController = new Controller()
      testController.view = new View()
      testController.title = 'Test Controller Title'

      # Payload for startupController event
      startupControllerContext =
        previousControllerName: 'null'
        controller: testController
        controllerName: 'test'
        params: {}

      # Create a fresh router
      router = new Router root: '/test/'

    afterEach ->
      layout.dispose()
      testController.dispose()
      router.dispose()

    it 'should hide the view of an inactive controller', ->
      testController.view.$el.css 'display', 'block'
      mediator.publish 'beforeControllerDispose', testController
      expect(testController.view.$el.css('display')).to.equal 'none'

    it 'should show the view of the active controller', ->
      testController.view.$el.css 'display', 'none'
      mediator.publish 'startupController', startupControllerContext
      $el = testController.view.$el
      expect($el.css('display')).to.equal 'block'
      expect($el.css('opacity')).to.equal '1'
      expect($el.css('visibility')).to.equal 'visible'

    it 'should set the document title', ->
      runs ->
        mediator.publish 'startupController', startupControllerContext
      waits 100
      runs ->
        title = "#{testController.title} \u2013 #{layout.title}"
        expect(document.title).to.equal title

    it 'should route clicks on internal links', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = '/an/internal/link'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      args = spy.mostRecentCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).to.equal path
      expect(passedCallback).to.be.a 'function'

    it 'should correctly pass the query string', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = '/another/link?foo=bar&baz=qux'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      args = spy.mostRecentCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).to.equal path
      expect(passedCallback).to.be.a 'function'
      mediator.unsubscribe '!router:route', spy

    it 'should not route links without href attributes', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a name="foo">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a>Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links with empty href', ->
      # Technically an empty string is a valid relative URL
      # but it doesn’t make sense to route it
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links to document fragments', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="#foo">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links with a noscript class', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="/leave-the-app" class="noscript">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route clicks on external links', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = 'http://www.example.org/'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should register event handlers on the document declaratively', ->
      spy1 = jasmine.createSpy()
      spy2 = jasmine.createSpy()
      layout.dispose()
      class TestLayout extends Layout
        events:
          'click #testbed': 'testClickHandler'
          click: spy2
        testClickHandler: spy1
      layout = new TestLayout
      el = $('#testbed')
      el.click()
      expect(spy1).toHaveBeenCalled()
      expect(spy2).toHaveBeenCalled()
      layout.dispose()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1

    it 'should register event handlers on the document programatically', ->
      expect(layout.delegateEvents is Backbone.View::delegateEvents)
        .to.be.ok
      expect(layout.undelegateEvents is Backbone.View::undelegateEvents)
        .to.be.ok
      expect(layout.delegateEvents).to.be.a 'function'
      expect(layout.undelegateEvents).to.be.a 'function'

      spy1 = jasmine.createSpy()
      spy2 = jasmine.createSpy()
      layout.testClickHandler = spy1
      layout.delegateEvents
        'click #testbed': 'testClickHandler'
        click: spy2
      el = $('#testbed')
      el.click()
      expect(spy1).toHaveBeenCalled()
      expect(spy2).toHaveBeenCalled()
      layout.undelegateEvents()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1

    it 'should dispose itself correctly', ->
      spy1 = jasmine.createSpy()
      layout.subscribeEvent 'foo', spy1

      spy2 = jasmine.createSpy()
      layout.delegateEvents 'click #testbed': spy2

      expect(layout.dispose).to.be.a 'function'
      layout.dispose()

      expect(layout.disposed).to.be.ok
      if Object.isFrozen
        expect(Object.isFrozen(layout)).to.be.ok

      mediator.publish 'foo'
      $('#testbed').click()

      # It should unsubscribe from events
      expect(spy1).not.toHaveBeenCalled()
      expect(spy2).not.toHaveBeenCalled()

    it 'should be extendable', ->
      expect(Layout.extend).to.be.a 'function'

      DerivedLayout = Layout.extend()
      derivedLayout = new DerivedLayout()
      expect(derivedLayout).to.be.an.instanceof Layout

      derivedLayout.dispose()
