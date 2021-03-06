defmodule STS.Transaction do
  use STS.Schema

  schema "transactions" do
    belongs_to(:sender, STS.Account)
    belongs_to(:receiver, STS.Account)
    field(:amount, :decimal)
    field(:sender_balance, :decimal)
    field(:receiver_balance, :decimal)
  end
end
