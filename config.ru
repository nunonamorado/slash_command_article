#\ -w -p 3000
# frozen_string_literal: true

require 'rubygems'
require 'dotenv/load'
require 'pry'

require File.expand_path 'app.rb', __dir__

run App.new
