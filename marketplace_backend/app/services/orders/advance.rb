module Orders
  class Advance
    Result = Struct.new(:success?, :order, :error_code, keyword_init: true)

    class << self
      def call(order:, actor:)
        new(order:, actor:).call
      end
    end

    def initialize(order:, actor:)
      @order = order
      @actor = actor
    end

    def call
      result = Orders::ApplyTransition.call(
        order: @order,
        actor: @actor,
        action: :advance,
        metadata: { "source" => "seller_advance" }
      )

      return Result.new(success?: false, error_code: result.error_code) unless result.success?

      Result.new(success?: true, order: result.order)
    end
  end
end
