# Main entry point into Chaplin module.
# Load all components and expose them.
module.exports =
  Application:    require 'chaplin/application'
  mediator:       require 'chaplin/mediator'
  Dispatcher:     require 'chaplin/dispatcher'
  Controller:     require 'chaplin/controllers/controller'
  Composer:       require 'chaplin/composer'
  Composition:    require 'chaplin/lib/composition'
  Collection:     require 'chaplin/models/collection'
  Model:          require 'chaplin/models/model'
  Layout:         require 'chaplin/views/layout'
  View:           require 'chaplin/views/view'
  CollectionView: require 'chaplin/views/collection_view'
  Route:          require 'chaplin/lib/route'
  Router:         require 'chaplin/lib/router'
  EventBroker:    require 'chaplin/lib/event_broker'
  support:        require 'chaplin/lib/support'
  SyncMachine:    require 'chaplin/lib/sync_machine'
  utils:          require 'chaplin/lib/utils'
