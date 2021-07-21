require "forwardable"

class Tartarus::Registry
  attr_reader :storage
  private     :storage

  extend Forwardable

  def_delegators :storage, :size, :each

  def initialize
    reset
  end

  def register(item)
    @storage << item
  end

  def find_by_name(name)
    storage.find(->{ raise "#{name} not found in registry" }) { |item| item.name == name }
  end

  def reset
    @storage = Concurrent::Array.new
  end
end
