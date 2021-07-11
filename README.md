# STS

Symple Transaction System is a small app to manage account information and submit transactions.

## Available functionality:

- Account: 
   * STS.list_accounts(): list all accounts
   * STS.find_account(id): find an account
   * STS.create_account(params): creates an account
   * STS.update_account(account, params): updates an account (balance can't be set below 0)
   
- Transaction:
   * STS.submit_transaction(sender, receiver, amount): submits an transaction.  sender has to have appropriate amount of balance to be able to submit.
   * STS.list_transactions(filter): list transactions, filter (account_id) is optional.

## How to run app:

```
$ iex -S mix
```

## How to run test:

```
$ mix test
```
