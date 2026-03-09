# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_09_210100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "cart_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "cart_id", null: false
    t.uuid "product_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_positive"
  end

  create_table "carts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_carts_on_user_id_and_status"
    t.index ["user_id"], name: "index_carts_on_user_id"
    t.index ["user_id"], name: "index_carts_on_user_id_active_unique", unique: true, where: "((status)::text = 'active'::text)"
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "product_id", null: false
    t.uuid "seller_id", null: false
    t.string "product_title", null: false
    t.integer "quantity", null: false
    t.bigint "unit_price_cents", null: false
    t.bigint "line_subtotal_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "idx_order_items_order_product_unique", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["seller_id", "created_at", "id"], name: "idx_order_items_seller_timeline"
    t.index ["seller_id"], name: "index_order_items_on_seller_id"
    t.check_constraint "line_subtotal_cents = (quantity * unit_price_cents)", name: "order_items_line_subtotal_matches_quantity"
    t.check_constraint "line_subtotal_cents > 0", name: "order_items_line_subtotal_positive"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    t.check_constraint "unit_price_cents > 0", name: "order_items_unit_price_positive"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "seller_id", null: false
    t.uuid "source_cart_id", null: false
    t.string "status", default: "paid", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "total_items", null: false
    t.bigint "subtotal_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "created_at", "id"], name: "idx_orders_seller_timeline"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["source_cart_id", "seller_id"], name: "idx_orders_source_cart_seller_unique", unique: true
    t.index ["source_cart_id"], name: "index_orders_on_source_cart_id"
    t.index ["user_id", "created_at", "id"], name: "idx_orders_buyer_timeline"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['paid'::character varying, 'in_separation'::character varying, 'confirmed'::character varying, 'delivered'::character varying, 'contested'::character varying, 'canceled'::character varying]::text[])", name: "orders_status_allowed"
    t.check_constraint "subtotal_cents > 0", name: "orders_subtotal_positive"
    t.check_constraint "total_items > 0", name: "orders_total_items_positive"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.decimal "price", precision: 9, scale: 2, null: false
    t.integer "stock_quantity", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["active"], name: "index_products_on_active"
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["user_id", "deleted_at"], name: "index_products_on_user_id_and_deleted_at"
    t.index ["user_id"], name: "index_products_on_user_id"
    t.check_constraint "stock_quantity >= 0", name: "products_stock_quantity_non_negative"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "full_name"
    t.string "address"
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "refresh_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "refresh_jti", null: false
    t.string "refresh_token_hash", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "rotated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_sessions_on_expires_at"
    t.index ["refresh_jti"], name: "index_refresh_sessions_on_refresh_jti", unique: true
    t.index ["user_id", "revoked_at"], name: "index_refresh_sessions_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_refresh_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  create_table "wallet_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "wallet_id", null: false
    t.string "transaction_type", null: false
    t.bigint "amount_cents", null: false
    t.bigint "balance_after_cents", null: false
    t.string "reference_type", null: false
    t.string "reference_id", null: false
    t.string "operation_key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wallet_id", "created_at", "id"], name: "idx_wallet_transactions_wallet_timeline"
    t.index ["wallet_id", "operation_key"], name: "idx_wallet_transactions_wallet_operation_key_unique", unique: true
    t.index ["wallet_id", "reference_type", "reference_id"], name: "idx_wallet_transactions_refund_reference_unique", unique: true, where: "((transaction_type)::text = 'refund'::text)"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
    t.check_constraint "amount_cents > 0", name: "wallet_transactions_amount_positive"
    t.check_constraint "balance_after_cents >= 0", name: "wallet_transactions_balance_after_non_negative"
    t.check_constraint "transaction_type::text = ANY (ARRAY['credit'::character varying, 'debit'::character varying, 'refund'::character varying]::text[])", name: "wallet_transactions_type_allowed"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.bigint "current_balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id", unique: true
    t.check_constraint "current_balance_cents >= 0", name: "wallets_current_balance_non_negative"
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "users", column: "seller_id"
  add_foreign_key "orders", "carts", column: "source_cart_id"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "seller_id"
  add_foreign_key "products", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "refresh_sessions", "users"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "users"
end
