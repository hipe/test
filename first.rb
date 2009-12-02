#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'

class MainController < Ramaze::Controller
  def index 
    'yo'
  end
end

Ramaze.start