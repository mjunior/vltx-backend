require "bigdecimal"

module Products
  class PublicListing
    Result = Struct.new(:success?, :products, :total, :error_code, keyword_init: true)

    ALLOWED_SORTS = %w[newest price_asc price_desc].freeze

    class << self
      def call(params:)
        new(params: params).call
      end
    end

    def initialize(params:)
      @params = params || {}
    end

    def call
      normalized = @params.to_h.symbolize_keys
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_params?(normalized)

      relation = Product.public_visible
      relation = apply_search(relation, normalized[:q])
      relation = apply_price_range(relation, normalized[:min_price], normalized[:max_price])
      relation = apply_sort(relation, normalized[:sort])

      total = relation.count
      Result.new(success?: true, products: relation.to_a, total: total)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_params?(params)
      min_price = normalize_filter_price(params[:min_price])
      max_price = normalize_filter_price(params[:max_price])
      return false if params[:min_price].present? && min_price.nil?
      return false if params[:max_price].present? && max_price.nil?
      return false if min_price && max_price && min_price > max_price
      return false if params[:sort].present? && !ALLOWED_SORTS.include?(params[:sort].to_s)

      true
    end

    def apply_search(relation, query)
      q = query.to_s.strip
      return relation if q.blank?

      escaped = ActiveRecord::Base.sanitize_sql_like(q)
      relation.where("title ILIKE :q OR description ILIKE :q", q: "%#{escaped}%")
    end

    def apply_price_range(relation, min_price_param, max_price_param)
      min_price = normalize_filter_price(min_price_param)
      max_price = normalize_filter_price(max_price_param)

      scoped = relation
      scoped = scoped.where("price >= ?", min_price) if min_price
      scoped = scoped.where("price <= ?", max_price) if max_price
      scoped
    end

    def apply_sort(relation, sort_param)
      sort = sort_param.to_s
      case sort
      when "price_asc"
        relation.order(price: :asc, created_at: :desc, id: :desc)
      when "price_desc"
        relation.order(price: :desc, created_at: :desc, id: :desc)
      else
        relation.order(created_at: :desc, id: :desc)
      end
    end

    def normalize_filter_price(value)
      return nil if value.blank?

      text = value.to_s.strip
      return nil unless text.match?(/\A\d+(?:\.\d{1,2})?\z/)

      BigDecimal(text)
    end
  end
end
