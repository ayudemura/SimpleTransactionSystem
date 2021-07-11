defmodule STSTest do
  use ExUnit.Case
  doctest STS

  describe "Accounts create" do
    test "successfully" do
      params = %{name: "Mickey Mouse"}
      assert {:ok, account} = STS.create_account(params)
      assert account.name == params.name
      assert Decimal.compare(account.balance, 10_000) == :eq
    end

    test "fails without name" do
      assert {:error, message} = STS.create_account(%{})
      assert inspect message.errors[:name] == {"can't be blank", [validation: :required]}
    end
  end

  describe "Accounts update" do
    setup do
      params = %{name: "Mickey Mouse"}
      {:ok, mickey} = STS.create_account(params)

      {:ok, mickey: mickey}
    end

    test "successfully", context do
      params = %{name: "Donald Duck", balance: 100}
      assert {:ok, account} = STS.update_account(context.mickey, params)
      assert account.name == params.name
      assert Decimal.compare(account.balance, params.balance) == :eq
    end
  end

  describe "Accounts list" do
    setup do
      params = %{name: "Mickey Mouse"}
      {:ok, mickey} = STS.create_account(params)

      params = %{name: "Minnie Mouse"}
      {:ok, minnie} = STS.create_account(params)

      {:ok, mickey: mickey, minnie: minnie}
    end

    test "successfully", context do
      assert {:ok, accounts} = STS.list_accounts()
      ids = Enum.map(accounts, & &1.id)
      assert context.mickey.id in ids
      assert context.minnie.id in ids
    end
  end

  describe "Accounts find" do
    setup do
      params = %{name: "Mickey Mouse"}
      {:ok, mickey} = STS.create_account(params)

      {:ok, mickey: mickey}
    end

    test "successfully", context do
      assert {:ok, account} = STS.find_account(context.mickey.id)
      assert account.id == context.mickey.id
    end
  end

  describe "Transaction submit" do
    setup do
      params = %{name: "Mickey Mouse"}
      {:ok, mickey} = STS.create_account(params)

      params = %{name: "Minnie Mouse"}
      {:ok, minnie} = STS.create_account(params)

      {:ok, mickey: mickey, minnie: minnie}
    end

    test "successfully", %{mickey: mickey, minnie: minnie} do
      amount = 500
      assert {:ok, transaction} = STS.submit_transaction(mickey, minnie, amount)
      assert transaction.sender_id == mickey.id
      assert transaction.receiver_id == minnie.id
      assert Decimal.compare(transaction.amount, amount) == :eq

      # sender balance
      balance = 10_000 - amount
      assert Decimal.compare(transaction.sender_balance, balance) == :eq
      {:ok, sender} = STS.find_account(mickey.id)
      assert Decimal.compare(sender.balance, balance) == :eq

      # receiver balance
      balance = 10_000 + amount
      assert Decimal.compare(transaction.receiver_balance, balance) == :eq
      {:ok, receiver} = STS.find_account(minnie.id)
      assert Decimal.compare(receiver.balance, balance) == :eq
    end

    test "fails when sender has 0 balance", %{mickey: mickey, minnie: minnie} do
      assert {:ok, mickey} = STS.update_account(mickey, %{balance: 0})
      assert {:error, message} = STS.submit_transaction(mickey, minnie, 500)
      assert message == :not_enough_balance
    end

    test "fails when sender has not enough balance", %{mickey: mickey, minnie: minnie} do
      assert {:ok, mickey} = STS.update_account(mickey, %{balance: 100})
      assert {:error, message} = STS.submit_transaction(mickey, minnie, 500)
      assert message == :not_enough_balance
    end
  end
end
