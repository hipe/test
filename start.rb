#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'
require 'ruby-debug'

module CommonController
  def self.extended klass
    klass.instance_eval do
      engine :Haml   
      layout 'default'  
    end
  end
end

class MainController < Ramaze::Controller 
  extend CommonController
  map '/'
  def index
    @content = 'my content'
  end
end

class ServicesController < Ramaze::Controller
  extend CommonController
  map '/sites'  
  def index
    @js = ['/js/page/sites.js']
    @content = 'my content'
  end
end

#
#class Services < Ramaze::Controller
#  map '/svc'
#  layout 'first'
#  
#  def index
#    @title = request[:name]
#  end  
#  
#  def check name
#    thing = Service[:name => name]
#    thing.checked = true
#    thing.save
#    redirect_referrer    
#  end
#  
#  def uncheck name
#    thing = Service[:name => name]
#    thing.checked = false
#    thing.save
#    redirect_referrer
#  end    
#  
#  def create
#    if request.post? and name = request[:name]
#      name.strip!
#      unless name.empty?       
#        Service.create :name => name
#      end
#    end
#    redirect  route('/', :name => name)
#  rescue Sequel::DatabaseError
#    redirect route('/', :name => name)    
#  end
#end
#
#
#

Ramaze.start
