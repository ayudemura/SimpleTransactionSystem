defmodule STS do
  import Ecto.{Changeset, Query}
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
  def update_account(account, params)
  def update_account(%{id: account_id}, params), do: update_account(account_id, params)
  def update_account(account_id, params) do
    Repo.transaction(fn ->
      with {:ok, account} <- find_account(account_id) do
        case Account.changeset(account, params) |> Repo.update() do
          {:ok, result} -> result
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  List transactions
  """
  def list_transactions(params \\ %{}) do
    with {:ok, query} <- filter(Transaction, params), do: {:ok, Repo.all(query)}
  end

  defp filter(query, %{account_id: id}) do
    {:ok,
      from(
        t in query,
        where: t.sender_id == ^id or t.receiver_id == ^id
      )
    }
  end

  defp filter(query, _), do: {:ok, query}

  @doc """
  Submit transaction

  sender - sender account or account id
  receiver - receiver account or account id
  amount - amount to send
  """
  def submit_transaction(sender, receiver, amount) do
    Repo.transaction(fn ->
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

        changeset = cast(%Transaction{}, params, [:amount, :sender_balance, :receiver_balance])
        |> put_assoc(:sender, sender_cs)
        |> put_assoc(:receiver, receiver_cs)

        case Repo.insert(changeset) do
          {:ok, result} -> result
          {:error, error} -> Repo.rollback(error)
        end
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  defp find_account_for(%Account{id: id}), do: find_account_for(id)
  defp find_account_for(account_id), do: find_account(account_id)

  defp valid_amount?(sender, amount) do
    if Decimal.compare(sender.balance, amount) == :lt,
      do: {:error, :not_enough_balance},
      else: :ok
  end
end
