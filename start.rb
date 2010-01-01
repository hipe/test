#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'
require 'ruby-debug'
require 'hipe-socialsync'

App = Hipe::SocialSync::App.new

Ramaze.options.dsl do
  o "uploaded wordpress files go here!",
    :wp_uploads, @hash[:roots][:value].first+'/tmp-uploads/wp-uploads/'
end

module CommonController
  def self.included klass
    klass.extend CommonControllerClassMethods
  end
  def err(str,extra)
    session[:err] = str
    redirect_referrer
  end
end

module CommonControllerClassMethods
  def self.extended klass
    klass.instance_eval do
      layout :default
      engine :Haml
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

class AccountsController < Ramaze::Controller
  extend CommonController
  map '/accounts'
  layout :default
  engine :Haml
  def index
    @js = ['/js/page/sites.js']
    @css = ['/css/page/accounts.css']    
    @content = 'wish you would see layout and template'
  end
end

# @x = request.params.pretty_inspect  TempFile.size  File.extname
class UploadsController < Ramaze::Controller
  extend CommonController
  map '/uploads'
  def wp    
    return err("this is for uploads only!",:type=>:err1) unless request.post?
    tempfile, filename, type = request[:file].values_at(:tempfile, :filename, :type)  
    new_path = File.join(Ramaze.options.wp_uploads,filename)
    FileUtils.move(tempfile.path,new_path)
    debugger
    respose = Hipe::SocialSync.new << request.POST

    session[:msg] = "upload success!"
    redirect_referrer
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
