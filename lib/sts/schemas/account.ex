defmodule STS.Account do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:name, :string)
    field(:balance, :decimal, default: 0)
  end

  def changeset(account \\ %__MODULE__{}, params) do
    account
    |> Ecto.Changeset.cast(params, [:name, :balance])
    |> Ecto.Changeset.validate_required([:name])
  end
end
