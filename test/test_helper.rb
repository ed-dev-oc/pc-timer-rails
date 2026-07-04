ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class Object
  def stub(name, val_or_callable, *args)
    original_method = method(name) rescue nil
    define_singleton_method(name) do |*m_args, &block|
      if val_or_callable.respond_to?(:call)
        val_or_callable.call(*m_args, &block)
      else
        val_or_callable
      end
    end
    yield
  ensure
    if original_method
      define_singleton_method(name, &original_method)
    else
      singleton_class.send(:remove_method, name) rescue nil
    end
  end
end
module HmacTestHelper
  def signed_headers(device, method:, path:, timestamp: Time.current.to_i, body: "")
    signature = HmacSigner.sign(device.secret, method, path, timestamp, body)
    {
      "X-DEVICE-ID" => device.device_id,
      "X-SIGNATURE" => signature,
      "X-TIMESTAMP" => timestamp.to_s
    }
  end
end

module BroadcastSuppressor
  def suppress_broadcasts
    original_broadcast = ActionCable.server.method(:broadcast) rescue nil
    ActionCable.server.define_singleton_method(:broadcast) { |*args| }
    yield
  ensure
    if original_broadcast
      ActionCable.server.define_singleton_method(:broadcast, &original_broadcast)
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      ActiveJob::Base.queue_adapter = :test
    end

    include BroadcastSuppressor
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include HmacTestHelper
end
