require "bigdecimal"

module Products
  class Create
    Result = Struct.new(:success?, :product, keyword_init: true)

    ALLOWED_KEYS = %i[title description price stock_quantity].freeze
    FORBIDDEN_KEYS = %i[owner_id user_id].freeze

    class << self
      def call(user:, params:)
        new(user: user, params: params).call
      end
    end

    def initialize(user:, params:)
      @user = user
      @params = params || {}
    end

    def call
      return Result.new(success?: false) unless @user

      normalized = @params.to_h.deep_symbolize_keys
      return Result.new(success?: false) if normalized.empty?
      return Result.new(success?: false) unless (normalized.keys - ALLOWED_KEYS).empty?
      return Result.new(success?: false) unless (normalized.keys & FORBIDDEN_KEYS).empty?

      attrs = {
        title: normalize_text(normalized[:title]),
        description: normalize_description(normalized[:description]),
        price: normalize_price(normalized[:price]),
        stock_quantity: normalize_stock(normalized[:stock_quantity]),
        active: true,
      }

      return Result.new(success?: false) if attrs.values_at(:title, :description, :price, :stock_quantity).any?(&:nil?)

      product = @user.products.new(attrs)
      return Result.new(success?: false) unless product.save

      Result.new(success?: true, product: product)
    rescue StandardError
      Result.new(success?: false)
    end

    private

    def normalize_text(value)
      return nil unless value.is_a?(String)

      text = value.strip
      return nil if text.empty?

      text
    end

    def normalize_description(value)
      text = normalize_text(value)
      return nil if text.nil?

      without_dangerous_blocks = text.gsub(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/im, "")
                                     .gsub(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/im, "")
      sanitized = ActionController::Base.helpers.strip_tags(without_dangerous_blocks).strip
      return nil if sanitized.empty?

      sanitized
    end

    def normalize_price(value)
      return nil if value.nil?

      text = value.to_s.strip
      return nil unless text.match?(/\A\d+(?:\.\d{1,2})?\z/)

      decimal = BigDecimal(text)
      return nil if decimal <= 0 || decimal > BigDecimal("9999999")

      decimal
    end

    def normalize_stock(value)
      return nil if value.nil?

      stock = if value.is_a?(Integer)
                value
              elsif value.is_a?(String) && value.match?(/\A\d+\z/)
                value.to_i
              else
                nil
              end
      return nil if stock.nil?
      return nil if stock.negative? || stock > 999_999

      stock
    end
  end
end
