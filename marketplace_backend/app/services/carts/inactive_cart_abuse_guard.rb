require "json"

module Carts
  class InactiveCartAbuseGuard
    Result = Struct.new(:count, :revoked, keyword_init: true)

    THRESHOLD = 3
    WINDOW = 10.minutes

    @memory_counters = {}
    @mutex = Mutex.new

    class << self
      def track!(user:, cart:, action:)
        count = increment_counter(user:, action:)
        revoked = count >= THRESHOLD

        Auth::Sessions::RevokeAll.call(user: user) if revoked
        log_attempt(user:, cart:, action:, count:, revoked:)

        Result.new(count: count, revoked: revoked)
      rescue StandardError
        Result.new(count: 0, revoked: false)
      end

      def reset!
        @mutex.synchronize { @memory_counters = {} }
      end

      private

      def increment_counter(user:, action:)
        key = cache_key(user:, action:)
        cache_count = Rails.cache.increment(key, 1, expires_in: WINDOW)
        return cache_count if cache_count

        increment_memory_counter(key)
      rescue StandardError
        increment_memory_counter(key)
      end

      def increment_memory_counter(key)
        now = Time.current

        @mutex.synchronize do
          entry = @memory_counters[key]
          if entry.nil? || entry[:expires_at] <= now
            @memory_counters[key] = { count: 1, expires_at: now + WINDOW }
          else
            entry[:count] += 1
          end

          @memory_counters[key][:count]
        end
      end

      def cache_key(user:, action:)
        "carts:inactive_abuse:user:#{user.id}:action:#{action}"
      end

      def log_attempt(user:, cart:, action:, count:, revoked:)
        payload = {
          event: "cart.inactive_mutation_attempt",
          user_id: user.id,
          cart_id: cart.id,
          status: cart.status,
          action: action,
          attempt_count: count,
          threshold: THRESHOLD,
          session_revoked: revoked,
          occurred_at: Time.current.utc.iso8601,
        }

        Rails.logger.warn(payload.to_json)
      rescue StandardError
        nil
      end
    end
  end
end
