#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'
require 'ruby-debug'
require 'hipe-socialsync'
require 'hipe-core/loquacious/all'
require 'hipe-cli/rack-land'
require 'orderedhash'

App = Hipe::SocialSync::App.new(['--env','dev'])
ping = App.run({"command_name"=>"ping", 'db'=>''})
if ping.valid?
  puts ping
else
  raise "socialsync backend startup problem: #{ping}"
end

Ramaze.options.dsl do
  o "uploaded wordpress files go here!",
    :wp_uploads, @hash[:roots][:value].first+'/tmp-uploads/wp-uploads/'
end

class CommonException < RuntimeError; end

class Zone
  # experimental top nav generation

  extend Hipe::Loquacious::AttrAccessor
  include Hipe::Loquacious::OpenSetter
  symbol_accessor :name
  string_accessor :url
  integer_accessor :index
  string_accessor :label

  def initialize name, opts = nil
    self.name = name
    open_set opts if opts
  end
  def self.construct *args
    Zone.new(*args)
  end
  def url
    @url || "/#{name}"
  end
  def label
    @label || @name
  end

end

Zones = OrderedHash.new
class << Zones
  alias_method :ohash_store, :store
  def store key, value
    raise CommonException.new("won't clobber #{key}") if has_key? key
    ohash_store key, value
  end
end

module CommonController
  def self.included klass
    klass.extend CommonControllerClassMethods
  end
  def escape_flash_string str
    result = h(str.strip)
    result.gsub!("\n", "<br/>\n")
    result
  end
  def set_error_flash str
    session[:err] = escape_flash_string(str)
  end
  def set_flash_from_response response
    session[response.valid? ? :msg : :err] = escape_flash_string(response.to_s)
  end
  def err(str,extra)
    set_error_flash(str)
    redirect_referrer
  end
  def common_setup
    @zones = Zones
  end
  def user
    current_user_email
  end
  def current_user_email
    'anonymous@sosy'
  end
end

module CommonControllerClassMethods
  def self.extended klass
    super
    klass.instance_eval do
      layout :default
      engine :Haml
    end
  end
  def register_zone *args
    zone = Zone.construct(*args)
    Zones[zone.name] = zone
  end
end

class MainController < Ramaze::Controller
  include CommonController
  register_zone :home, :index => 100, :url=>'/', :label =>'home'
  map '/'
  def index
    @content = 'my content'
  end
end

class AccountsController < Ramaze::Controller
  include CommonController
  map '/accounts'
  register_zone :accounts, :index => 102, :label=>'your sites'

  def index
    common_setup
    @js = ['/js/page/common.js','/js/page/sites.js']
    @css = ['/css/page/accounts.css']
    @content = 'wish you would see layout and template'
    result = App.run({"command_name"=>"accounts:list"}, user)
    if (result.valid?)
      @table = result.data.tables[0]
    else
      set_error_flash(result.to_s)
    end
  end

  def add
    response = App.run(request.params, user)
    set_flash_from_response(response)
    redirect_referrer
  end

  def edit
    my_request = request.params.dup
    my_request["command_name"] = "accounts:"+my_request["command_name"]
    response = App.run(my_request, user)
    set_flash_from_response(response)
    redirect_referrer
  end
end

# @x = request.params.pretty_inspect  TempFile.size  File.extname
class UploadsController < Ramaze::Controller
  include CommonController
  map '/uploads'
  register_zone :uploads, :index => 354, :label =>'your uploads'
  def wp
    return err("this is for uploads only!",:type=>:err1) unless request.post?
    tempfile, filename, type = request[:file].values_at(:tempfile, :filename, :type)
    new_path = File.join(Ramaze.options.wp_uploads,filename)
    FileUtils.move(tempfile.path,new_path)
    my_request = {
      'command_name'            => 'wp:pull',
      'xml_in'                  => new_path,
      'service_credential_name' => File.basename(new_path),
      'auto-create-account'     => ""
    }
    response = App.run(my_request,user)
    set_flash_from_response(response)
    redirect_referrer
  end
end


# @x = request.params.pretty_inspect  TempFile.size  File.extname
class ItemsController < Ramaze::Controller
  include CommonController
  map '/items'
  register_zone :items, :index => 301, :label =>'your blogs'

  def index
    common_setup
    my_request = request.params.dup
    my_request.merge!("command_name" => "items:list", "user" => current_user_email)
    result = App.run my_request, user
    if result.valid? and result.data.tables
      prepare_table(result.data)
    else
      set_flash_from_response(result)
    end
    @js = ['/js/page/common.js','/js/page/items.js']
    @css = ['/css/page/items.css']
  end

  def prepare_table(data)
    @table = data.tables[0]
    @table.field[:account].renderer = lambda{|x| x.truncate(x.account.one_word,10) }
    @table.field[:title].renderer = lambda{|x| x.truncate(x.title,30) }
    title_elements = []
    if data.account
      title_elements << "account #{data.account.one_word.inspect}"
      @table.field[:user].hide()
      @table.field[:account].hide()
    elsif data.user
      title_elements << "user #{data.user.one_word}"
      @table.field[:user].hide()
    end
    if data.service
      title_elements << "#{@data.service.one_word}"
    end
    @table_title = title_elements.size > 0 ? %{items from #{title_elements.join(' ')}} : "all items"
    @fields = @table.visible_fields
    @inners = @fields.dup
    @left = @inners.shift
    @right = @inners.pop
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
# debugger
# 'x'
# if request.post? and name = request[:name]
#   name.strip!
#   unless name.empty?
#     Service.create :name => name
#   end
# end
# redirect  route('/', :name => name)
# rescue Sequel::DatabaseError
#    redirect route('/', :name => name)
#  end

#
#
#
Zones.instance_variable_get('@order').sort!{|x,y| Zones[x].index <=> Zones[y].index }
Ramaze.start
