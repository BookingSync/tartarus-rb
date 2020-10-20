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

  def find_by_model(model)
    storage.find(->{ raise "#{model} not found in registry" }) { |item| item.for_model?(model) }
  end

  def reset
    @storage = Concurrent::Array.new
  end
end
