# frozen_string_literal: true

require 'sqlite3'
require 'active_record'
require 'database_cleaner'

ENV['RAILS_ENV'] ||= 'test'

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :owners, force: true do |t|
    t.string :name
  end
  create_table :pets, force: true do |t|
    t.string :name
    t.references :owner
  end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Owner < ApplicationRecord
  has_many :pets

  def self.trigger(arg); end

  def my_name_is
    self.class.trigger("Hello, my name is #{name}")
  end

  def greetings(your_name)
    self.class.trigger("Hello, #{your_name}. I'm #{name}")
  end
end

class Pet < ApplicationRecord
  belongs_to :owner
end

# database cleaner

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
