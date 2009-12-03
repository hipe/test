require 'sequel'

Sequel::Model.plugin(:schema)

DB = Sequel.sqlite('mine.db')

require 'model/service'