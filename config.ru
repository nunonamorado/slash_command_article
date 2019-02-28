#\ -w -p 3000
# frozen_string_literal: true

require "rubygems"
require "sinatra/slack"
require "pry"

require File.expand_path '../app.rb', __FILE__

run App.new
