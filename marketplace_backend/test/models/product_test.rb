require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def build_user(email: "seller@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  test "is valid with required fields" do
    user = build_user
    product = Product.new(
      user: user,
      title: "Notebook Gamer",
      description: "Notebook com placa dedicada e 16GB de RAM",
      price: "7999.99",
      stock_quantity: 10,
      active: true
    )

    assert product.valid?
  end

  test "requires title and description length constraints" do
    user = build_user(email: "lengths@example.com")
    product = Product.new(
      user: user,
      title: "ab",
      description: "curta",
      price: "100.00",
      stock_quantity: 1,
      active: true
    )

    assert_not product.valid?
    assert_includes product.errors[:title], "is too short (minimum is 3 characters)"
    assert_includes product.errors[:description], "is too short (minimum is 10 characters)"
  end

  test "requires price and stock limits" do
    user = build_user(email: "limits@example.com")
    product = Product.new(
      user: user,
      title: "Produto Limites",
      description: "Descricao longa o suficiente para passar tamanho",
      price: "10000000.00",
      stock_quantity: 1_000_000,
      active: true
    )

    assert_not product.valid?
    assert_includes product.errors[:price], "must be less than or equal to 9999999"
    assert_includes product.errors[:stock_quantity], "must be less than or equal to 999999"
  end
end
