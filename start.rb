#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'
require 'ruby-debug'
require 'hipe-socialsync'
require 'hipe-core/loquacious/all'
require 'hipe-core/lingual/ascii-typesetting'
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
    result = h(str).gsub!("\n", "<br/>\n").gsub!(' ','&nbsp;')  # no strip -- leading w/s can be meaningful
    result
  end
  def set_error_flash str
    session[:err] = escape_flash_string(str)
  end
  def set_flash_from_response response
    session[response.valid? ? :msg : :err] = escape_flash_string(response.to_s)
  end
  def set_flash mixed
    if mixed.respond_to?(:valid?)
      set_flash_from_response mixed
    else
      session[:msg] = mixed.to_s
    end
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

  # turns {"10"=>"foo","11"=>"foo","12"=>"foo"} into {"foo"=>"10,11,12"}
  def checkbox_flip(request_hash, element_name)
    arr = []
    request_hash.select{|k,v| v==element_name}.each do |pair|
      arr << pair[0]
      request_hash.delete(pair[0])
    end
    request_hash[element_name] = arr*','
  end

  def string_prepend prepend, str
    str.replace %{#{prepend}#{str}}
  end

  def rackize opts
    params = request.params
    if params['command_name']
      string_prepend(opts[:plugin], params['command_name']) if opts[:plugin]
    else
      params['command_name'] = request.env['PATH_INFO'].scan(%r|/([^/]+)|).map{|x| x[0]}.join(':')
    end
    checkbox_flip params, opts[:cb] if opts[:cb]
    opts[:rename].each do |k,v|
      params[v] = params.delete(k)
    end if opts[:rename]
    params
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


module RenderTable; end
module RenderButtons; end

module CommonView
  include Hipe::AsciiTypesetting::Methods # truncate
  include RenderTable, RenderButtons

  def render_testo
    @i_am_data_set_in_the_partial_controller = "D.S.I.T.P.C"
    Ramaze::View::Haml.call action, Innate::View.read(File.expand_path('../../partials/tpartial.haml', action.view));
  end

  def humanize_lite str
    str.to_s.gsub '_', ' '
  end

end


# **************** experimental partials ************

module RenderTable

  Defaults = {
    :top_separator_html => '<div class="separator">  | </div>',
    :separator_html     => '',
    :resize => [:cdrag],
    :checkboxes => false,
  }

  def render_table(table, opts={})
    @_table = table;
    opts = Defaults.merge(opts);
    @_table_cdrag = opts[:resize].include? :cdrag
    @_table_wdrag = opts[:resize].include? :wdrag
    @_table_sdrag = opts[:resize].include? :sdrag
    @_table_edrag = opts[:resize].include? :edrag
    fields = table.visible_fields
    opts[:row_coda] = :buttons if !opts.has_key?(:row_coda)
    opts.delete(:row_coda) unless table.has_visible_field?(opts[:row_coda])
    if table.has_visible_field?(:buttons) && !opts.has_key?(:no_escape)
      opts[:no_escape] = [:buttons]
    else
      opts[:no_escape] ||= []
    end
    @_table_all_visible_fields = fields.dup
    @_table_raw = Hash[*opts[:no_escape].map{|x| [x,true]}.flatten]
    @_table_none = false
    @_table_solo = nil
    @_table_left = nil
    @_table_rite = nil
    @_table_codas = opts[:row_coda] ? fields.slice!(fields.index{|x| x.name==opts[:row_coda]},fields.length) : []
    case fields.length
      when 0 then @_table_none = true
      when 1 then @_table_solo = fields.pop
      else
        @_table_left = fields.shift
        @_table_rite = fields.pop
    end
    @_table_inner = fields # empty ok
    @_table_fields = @_table.visible_fields
    @_table_opts = opts
    rs = Ramaze::View::Haml.call action, Innate::View.read(File.expand_path('../../partials/table.haml', action.view))
    rs[0]
  end

end

module Buttons
  class Button
    include CommonView; # humanize_lite
    include Hipe::Loquacious::OpenSetter
    extend Hipe::Loquacious::AttrAccessor
    symbol_accessor :name
    string_accessors :action, :href, :label
    integer_accessor :object_id
    def initialize name, opts={}
      opts[:name] = name
      open_set opts
    end
    def label; @label || humanize_lite(@name) end
  end
  def self.make &block
    @buttons = OrderedHash.new
    instance_eval(&block)
    @buttons
  end
  def self.button(*args)
    button = Button.new(*args)
    @buttons[button.name] = button
    button
  end
end

module RenderButtons
  def render_buttons buttons
    @_buttons = buttons
    @_buttons_opts = {}
    rs = Ramaze::View::Haml.call action, Innate::View.read(File.expand_path('../../partials/buttons.haml', action.view))
    rs[0]
  end
end

# *************** end experimental partials ***************




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
    set_flash App.run(request.params, user)
    redirect_referrer
  end

  def edit
    my_request = request.params.dup
    my_request["command_name"] = "accounts:"+my_request["command_name"]
    set_flash App.run(my_request, user)
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
    set_flash App.run(my_request,user)
    redirect_referrer
  end
end


# @x = request.params.pretty_inspect  TempFile.size  File.extname
class ItemsController < Ramaze::Controller
  include CommonController
  include CommonView
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
      set_flash result
    end
    @accounts = App.run({'command_name'=>'accounts:list'}, user).data.accounts
    @js = ['/js/page/common.js','/js/page/items.js']
    @css = ['/css/page/items.css']
  end

  def edit
    set_flash App.run(rackize(:cb=>'item_ids',:plugin=>'items:'), user)
    redirect_referrer
  end

  def view
    common_setup
    @js = [
      '/js/page/common.js',
      '/histeria/js/jquery/latest/ui/ui.core.js',
      '/histeria/js/resizable-table.js',
      '/js/page/items.js'
    ]
    result = App.run(rackize(:rename=>{"o"=>"id"}), user)
    @tables = result.data.tables
    @tables["items"].field[:excerpt].renderer = lambda{|x| truncate(x.content, 90) }
    @tables["items"].field[:title].renderer = lambda{|x| truncate(x.title, 90) }
    @tables["events"].field(:buttons, :show_header=>false) do |event|
      bs = Buttons.make do
        button :one_thing, :object_id => event.id
        button :do_this, :href => "/go/here"
      end
      render_buttons(bs)
    end
  end

  def prepare_table(data)
    @table = data.tables[0]
    @table.field[:account].renderer = lambda{|x| truncate(x.account.one_word,10) }
    @table.field[:title].renderer = lambda{|x| truncate(x.title,30) }
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

  include CommonView
end



class TestController < Ramaze::Controller
  include CommonController
  include CommonView
  map '/_test'
  register_zone :_test, :index => 999, :label =>'test'

  def index
    common_setup
    if (name = request.params["name"])
    else
      @tests = self.class.instance_methods(false).grep(/^[^_]/).sort;
      @tests.reject!{|x| ['index','run'].include? x}
    end
    @js = ['/js/page/common.js']
  end

  def partial
    @some_data_set_in_the_actual_controller = 'S.D.S.I.T.A.C'
  end

  def buttons
    common_setup
    @js = ['/js/page/common.js']
    @buttons = Buttons.make do
      button(:action1, :label=>'button for going back to tests', :href=>"/_test/index")
      button(:another_action, :label=>'a click hack',:object_id=>1)
    end
  end

  def run
    name = request.params.keys.first
    if respond_to? name
      redirect route(%{/#{name}})
    else
      set_error_flash %{invalid test #{name.inspect}}
      redirect_referrer
    end
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
