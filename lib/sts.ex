defmodule STS do
  import Ecto.Changeset
  alias STS.{Repo, Account, Transaction}

  @moduledoc """
  Documentation for Simple Transaction System.
  """

  @doc """
  List accounts
  """
  def list_accounts(), do: {:ok, Repo.all(Account)}

  @doc """
  find an account
  """
  def find_account(id) do
    case Repo.get(Account, id) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Create an account with default balance of 10,000
  """
  def create_account(params) do
    params = Map.put(params, :balance, 10_000)
    Account.changeset(params) |> Repo.insert()
  end

  @doc """
  Update an account with given params (name and/or balance)
  """
  def update_account(account, params) do
    Account.changeset(account, params) |> Repo.update()
  end

  @doc """
  List transactions
  """
  def list_transactions(), do: Repo.all(Transaction)

  @doc """
  Submit transaction

  sender - sender account or account id
  receiver - receiver account or account id
  amount - amount to send
  """
  def submit_transaction(sender, receiver, amount) do
    with {:ok, sender} <- find_account_for(sender),
         {:ok, receiver} <- find_account_for(receiver),
         :ok <- valid_amount?(sender, amount) do

      sender_balance = Decimal.sub(sender.balance, amount)
      receiver_balance = Decimal.add(receiver.balance, amount)

      params = %{
        amount: amount,
        sender_balance: sender_balance,
        receiver_balance: receiver_balance
      }

      sender_cs = change(sender, balance: sender_balance)
      receiver_cs = change(receiver, balance: receiver_balance)

      cast(%Transaction{}, params, [:amount, :sender_balance, :receiver_balance])
      |> put_assoc(:sender, sender_cs)
      |> put_assoc(:receiver, receiver_cs)
      |> Repo.insert()
    end
  end

  defp find_account_for(%Account{} = account), do: {:ok, account}
  defp find_account_for(account_id), do: find_account(account_id)

  defp valid_amount?(sender, amount) do
    if Decimal.compare(sender.balance, amount) == :lt,
      do: {:error, :not_enough_balance},
      else: :ok
  end
end
