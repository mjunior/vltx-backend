class AddWalletTransactionsAppendOnlyTrigger < ActiveRecord::Migration[8.0]
  FUNCTION_NAME = "wallet_transactions_append_only".freeze
  TRIGGER_NAME = "trg_wallet_transactions_append_only".freeze

  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        RAISE EXCEPTION 'wallet_transactions is append-only';
      END;
      $$;
    SQL

    execute <<~SQL
      CREATE TRIGGER #{TRIGGER_NAME}
      BEFORE UPDATE OR DELETE ON wallet_transactions
      FOR EACH ROW
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS #{TRIGGER_NAME} ON wallet_transactions"
    execute "DROP FUNCTION IF EXISTS #{FUNCTION_NAME}()"
  end
end
