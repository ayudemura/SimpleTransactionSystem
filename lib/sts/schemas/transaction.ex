defmodule STS.Transaction do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    belongs_to(:sender, STS.Account)
    belongs_to(:receiver, STS.Account)
    field(:amount, :decimal)
    field(:sender_balance, :decimal)
    field(:receiver_balance, :decimal)
  end
end
