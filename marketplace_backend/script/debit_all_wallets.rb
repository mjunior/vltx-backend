# frozen_string_literal: true

# Usage (Rails console):
#   load Rails.root.join("script/debit_all_wallets.rb")
#   DebitAllWallets.run!(batch_key: "debit-2026-03-08")
#
# Usage (runner):
#   bundle exec rails runner "load Rails.root.join('script/debit_all_wallets.rb'); DebitAllWallets.run!(batch_key: 'debit-2026-03-08')"

class DebitAllWallets
  DEBIT_CENTS = 300 # R$3,00

  def self.run!(batch_key:, dry_run: false)
    raise ArgumentError, "batch_key is required" if batch_key.to_s.strip.empty?

    totals = {
      users: 0,
      debited: 0,
      insufficient_funds: 0,
      conflicts: 0,
      failed: 0,
    }

    User.find_each do |user|
      totals[:users] += 1
      wallet = Wallet.find_or_create_by!(user: user)

      operation_key = "admin-debit:#{batch_key}:wallet:#{wallet.id}"

      if dry_run
        puts "[DRY-RUN] user=#{user.id} wallet=#{wallet.id} op_key=#{operation_key} amount_cents=#{DEBIT_CENTS}"
        next
      end

      result = Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: :debit,
        trusted_amount_cents: DEBIT_CENTS,
        reference_type: "admin_batch_debit",
        reference_id: batch_key,
        operation_key: operation_key,
        metadata: {
          "source" => "admin_script",
          "reason" => "global_debit",
          "note" => "R$3 debit for all users"
        }
      )

      if result.success?
        totals[:debited] += 1
      elsif result.error_code == :insufficient_funds
        totals[:insufficient_funds] += 1
        puts "[INSUFFICIENT] user=#{user.id} wallet=#{wallet.id}"
      elsif result.error_code == :idempotency_conflict
        totals[:conflicts] += 1
        puts "[CONFLICT] user=#{user.id} wallet=#{wallet.id} op_key=#{operation_key}"
      else
        totals[:failed] += 1
        puts "[FAILED] user=#{user.id} wallet=#{wallet.id} error=#{result.error_code}"
      end
    end

    puts "DONE users=#{totals[:users]} debited=#{totals[:debited]} insufficient_funds=#{totals[:insufficient_funds]} conflicts=#{totals[:conflicts]} failed=#{totals[:failed]}"
    totals
  end
end
