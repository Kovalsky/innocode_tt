require 'redis'
require 'connection_pool'

class RedisStore
  def initialize(url:, pool_size:, timeout:)
    @pool = ConnectionPool.new(size: pool_size, timeout: timeout) do
      Redis.new(url: url)
    end
  end

  def get(key)
    @pool.with { |conn| conn.get(key) }
  end

  def set(key, value, expires_in: nil)
    @pool.with do |conn|
      expires_in ? conn.set(key, value, ex: expires_in) : conn.set(key, value)
    end
  end
end
