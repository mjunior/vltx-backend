require "bigdecimal"

module Products
  class Update
    Result = Struct.new(:success?, :product, :error_code, keyword_init: true)

    ALLOWED_KEYS = %i[title description price stock_quantity active].freeze

    class << self
      def call(user:, product_id:, params:)
        new(user: user, product_id: product_id, params: params).call
      end
    end

    def initialize(user:, product_id:, params:)
      @user = user
      @product_id = product_id
      @params = params || {}
    end

    def call
      product = find_owned_product
      return Result.new(success?: false, error_code: :not_found) unless product

      normalized = @params.to_h.deep_symbolize_keys
      return Result.new(success?: false, error_code: :invalid_payload) if normalized.empty?
      return Result.new(success?: false, error_code: :invalid_payload) unless (normalized.keys - ALLOWED_KEYS).empty?
      return Result.new(success?: false, error_code: :invalid_payload) if normalized[:active] == false

      attrs = {}
      attrs[:title] = normalize_text(normalized[:title]) if normalized.key?(:title)
      attrs[:description] = normalize_description(normalized[:description]) if normalized.key?(:description)
      attrs[:price] = normalize_price(normalized[:price]) if normalized.key?(:price)
      attrs[:stock_quantity] = normalize_stock(normalized[:stock_quantity]) if normalized.key?(:stock_quantity)
      attrs[:active] = true if normalized[:active] == true

      return Result.new(success?: false, error_code: :invalid_payload) if attrs.empty?
      return Result.new(success?: false, error_code: :invalid_payload) if attrs.values.any?(&:nil?)
      return Result.new(success?: false, error_code: :invalid_payload) unless product.update(attrs)

      Result.new(success?: true, product: product)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def find_owned_product
      return nil unless @user

      @user.products.not_deleted.find_by(id: @product_id)
    end

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
