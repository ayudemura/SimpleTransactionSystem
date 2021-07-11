defmodule STS.Repo.Migrations.AddAccountsAndTransactions do
  use Ecto.Migration

  def change do
    create table("accounts", primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:balance, :decimal)
    end

    create table("transactions", primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:sender_id, references("accounts", type: :binary_id))
      add(:receiver_id, references("accounts", type: :binary_id))
      add(:amount, :decimal)
      add(:sender_balance, :decimal)
      add(:receiver_balance, :decimal)
    end
  end
end
