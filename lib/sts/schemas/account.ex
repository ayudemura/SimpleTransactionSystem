defmodule STS.Account do
  use STS.Schema

  schema "accounts" do
    field(:name, :string)
    field(:balance, :decimal, default: 0)
  end

  def changeset(account \\ %__MODULE__{}, params) do
    account
    |> cast(params, [:name, :balance])
    |> validate_required([:name])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
  end
end
