# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class ConciliateAccount
  attr_reader :account_ledger

  delegate :account, :account_to, :amount, :amount_currency, to: :account_ledger

  def initialize(ledger)
    raise 'an AccountLedger instance was expected' unless ledger.is_a?(AccountLedger)
    @account_ledger = ledger
  end

  def conciliate
    account_ledger.conciliation = true
    update_account_ledger_approver

    return account_ledger.save if is_service_payment?

    case account.class.to_s
    when 'Income', 'Expense'
      update_account_to
    else
      update_both_accounts
    end
  end

private
  def is_service_payment?
    [Income, Expense].include?(account_to.class)
  end

  def update_account_to
    account_to.amount += amount_currency

    account_to.save && account_ledger.save
  end

  def update_both_accounts
    account.amount -= amount
    account_to.amount += amount_currency

    account.save && account_to.save && account_ledger.save
  end

  def update_account_ledger_approver
    account_ledger.approver_id = UserSession.id
    account_ledger.approver_datetime = Time.zone.now
  end
end