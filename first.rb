#!/usr/bin/env ruby
require 'rubygems'
require 'ramaze'

class MainController < Ramaze::Controller
  
  def index 
    'yo'
  end
end

class BlogController < Ramaze::Controller
  map '/blogs'
  
  def index
    'ramaze still rocks'
  end
end


Ramaze.start