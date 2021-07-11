defmodule STS.Repo do
  use Ecto.Repo,
    otp_app: :sts,
    adapter: Ecto.Adapters.Postgres
end
