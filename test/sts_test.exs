defmodule STSTest do
  use ExUnit.Case
  doctest STS

  setup do
    params = %{name: "Mickey Mouse"}
    {:ok, mickey} = STS.create_account(params)

    params = %{name: "Minnie Mouse"}
    {:ok, minnie} = STS.create_account(params)

    {:ok, mickey: mickey, minnie: minnie}
  end

  describe "Accounts create" do
    test "successfully" do
      params = %{name: "Daisey Duck"}
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
    test "successfully", context do
      params = %{name: "Donald Duck", balance: 100}
      assert {:ok, account} = STS.update_account(context.mickey, params)
      assert account.name == params.name
      assert Decimal.compare(account.balance, params.balance) == :eq
    end

    test "fails if balance is below 0", context do
      params = %{balance: -1}
      assert {:error, message} = STS.update_account(context.mickey, params)
      assert message.errors[:balance]
    end
  end

  describe "Accounts list" do
    test "successfully", context do
      assert {:ok, accounts} = STS.list_accounts()
      ids = Enum.map(accounts, & &1.id)
      assert context.mickey.id in ids
      assert context.minnie.id in ids
    end
  end

  describe "Accounts find" do
    test "successfully", context do
      assert {:ok, account} = STS.find_account(context.mickey.id)
      assert account.id == context.mickey.id
    end
  end

  describe "Transaction submit" do
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

  describe "Transactions list" do
    setup context do
      amount = 500
      assert {:ok, t1} = STS.submit_transaction(context.mickey, context.minnie, amount)
      assert {:ok, t2} = STS.submit_transaction(context.mickey, context.minnie, amount)

      {:ok, t1: t1, t2: t2, amount: amount}
    end

    test "successfully",
      %{mickey: mickey, minnie: minnie, t1: t1, t2: t2, amount: amount} do
      {:ok, list} = STS.list_transactions()
      ids = Enum.map(list, & &1.id)
      assert t1.id in ids
      assert t2.id in ids

      {:ok, mickey} = STS.find_account(mickey.id)
      new_balance =
        10_000
        |> Decimal.sub(amount)
        |> Decimal.sub(amount)
      assert Decimal.compare(mickey.balance, new_balance) == :eq

      {:ok, minnie} = STS.find_account(minnie.id)
      new_balance =
        10_000
        |> Decimal.add(amount)
        |> Decimal.add(amount)
      assert Decimal.compare(minnie.balance, new_balance) == :eq
    end

    test "returns filtered transactions", %{mickey: mickey, t1: t1, t2: t2} do
      params = %{name: "Donald Duck"}
      assert {:ok, donald} = STS.create_account(params)
      assert {:ok, t3} = STS.submit_transaction(mickey, donald, 500)

      {:ok, list} = STS.list_transactions(%{account_id: mickey.id})
      ids = Enum.map(list, & &1.id)
      assert t1.id in ids
      assert t2.id in ids
      assert t3.id in ids

      {:ok, list} = STS.list_transactions(%{account_id: donald.id})
      ids = Enum.map(list, & &1.id)
      refute t1.id in ids
      refute t2.id in ids
      assert t3.id in ids
    end
  end
end
