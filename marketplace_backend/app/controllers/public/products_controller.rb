module Public
  class ProductsController < ApplicationController
    def index
      result = Products::PublicListing.call(params: listing_params.to_h)
      return render_invalid_payload unless result.success?

      render json: {
        data: result.products.map { |product| Products::PublicProductSerializer.call(product: product) },
        meta: { total: result.total },
      }, status: :ok
    end

    def show
      result = Products::PublicProductDetail.call(id: params[:id])
      return head :not_found unless result.success?

      render json: {
        data: Products::PublicProductDetailSerializer.call(product: result.product),
      }, status: :ok
    end

    private

    def listing_params
      params.permit(:q, :min_price, :max_price, :sort)
    end
  end
end
