# Transactions & entries

This document describes how transactions and entries are recorded in the eWallet and Local Ledger
databases using the double bookkeeping system.

## Double entry bookkeeping

Double entry bookkeeping is a systematic way to record the flow of funds between
different entities, in this case being wallets.

Each transaction comprises of at least two entries affecting different accounts, one debit
and one credit. The sum of the debit amounts and the sum of credit amounts in each transaction
are always equal. If the sums are different, the transaction and entries must be considered
invalid and not accepted into the Local Ledger database in the first place.

This system allows for a consistent audit trail where every single unit of funds are always
accounted for, and balances for any point in time can be computed with accuracy using these
transactions and debit/credit entries.

## eWallet transactions

An eWallet transaction is the record of the original intent and stores any extra data associated
with the intent. It is not aware of how the accounting or transfer is done behind the scene but
contains useful user-facing information such as the source and destination of funds for the
transaction, the extra metadata provided by the provider, etc.

The existent of this transaction does not imply that the transaction occured successfully.
Instead, the success or failure of the transaction can be determined by looking at
the transaction's `status` attribute, along with any `error_code`, `error_description`
and `error_data` associated with the record.

## Local Ledger transactions

A Local Ledger transaction is a logical group of debit/credit entries that satisfies
an eWallet transaction.

Each Local Ledger transaction is associated with an eWallet transaction. On the other hand,
an eWallet transaction may or may not associate with a Local Ledger transaction.
In this latter case, it must be associated with a transaction that occurs somewhere else,
such as a transaction on the blockchain.

The sum of debit amounts and the sum of credit amounts must be equal within each Local Ledger
transaction.

## Local Ledger entries

A Local Ledger entry can be either a `debit` or `credit` type. Each entry represents a change
in value in a wallet.

While the double entry bookkeeping system has a proper definition for debit and credit,
**it's safe to say within this eWallet context that a debit entry removes funds from a wallet,
while a credit entry adds funds to a wallet.**

In some cases, looking at the entries alone may be counter-intuitive. The examples below
highlight some intuitive and counter-intuitive records that may arise in your Local Ledger
database.

## Examples

Note: Fields are shortened or removed, and values are shortened for readability.

### Same-token transfers

eWallet transaction:

|    id    |      from | from_amount | from_token |        to | to_amount | to_token | exchange_wallet |  status | ledger_uuid |
|    ----: |     ----: |       ----: |      ----: |     ----: |     ----: |    ----: |           ----: |   ----: |       ----: |
| txn_1234 | wllt_1111 |        1000 |    tok_ETH | wllt_2222 |      1000 |  tok_ETH |          *NULL* | success |    5bc8a6f5 |

Local Ledger transaction:

|     uuid |
|    ----: |
| 5bc8a6f5 |

Local Ledger entries:

| transaction_uuid |     uuid |   type |   address | amount | token_id |
|            ----: |     ---: |   ---: |      ---: |   ---: |     ---: |
|         5bc8a6f5 | 7457e16a |  debit | wllt_1111 |   1000 |  tok_ETH |
|         5bc8a6f5 | 28de919c | credit | wllt_2222 |   1000 |  tok_ETH |

### Cross-token transfers

eWallet transaction:

|    id    |      from | from_amount | from_token |        to | to_amount | to_token | exchange_wallet |  status | ledger_uuid |
|    ----: |     ----: |       ----: |      ----: |     ----: |     ----: |    ----: |           ----: |   ----: |       ----: |
| txn_1234 | wllt_1111 |        1000 |    tok_ETH | wllt_2222 |      5000 |  tok_OMG |       exhg_9999 | success |    b83abefd |

Local Ledger transaction:

|     uuid |
|    ----: |
| b83abefd |

Local Ledger entries:

| transaction_uuid |     uuid |   type |   address | amount | token_id |
|            ----: |     ---: |   ---: |      ---: |   ---: |     ---: |
|         b83abefd | 891dd719 |  debit | wllt_1111 |   1000 |  tok_ETH |
|         b83abefd | 0c01836f | credit | exhg_9999 |   1000 |  tok_ETH |
|         b83abefd | aa216b0e |  debit | exhg_9999 |   5000 |  tok_OMG |
|         b83abefd | de13a367 | credit | wllt_2222 |   5000 |  tok_OMG |

Notice that 4 entries are needed. Two for moving ETH funds from the source to the exchange wallet.
Another two for moving OMG funds from the exchange to the destination wallet.

### Cross-token transfers from/to an exchange account

eWallet transaction:

|    id    |      from | from_amount | from_token |        to | to_amount | to_token | exchange_wallet |  status | ledger_uuid |
|    ----: |     ----: |       ----: |      ----: |     ----: |     ----: |    ----: |           ----: |   ----: |       ----: |
| txn_1234 | wllt_1111 |        1000 |    tok_ETH | exhg_9999 |      5000 |  tok_OMG |       exhg_9999 | success |    b83abefd |

Local Ledger transaction:

|     uuid |
|    ----: |
| b83abefd |

Local Ledger entries:

| transaction_uuid |     uuid |   type |   address | amount | token_id |
|            ----: |     ---: |   ---: |      ---: |   ---: |     ---: |
|         b83abefd | 777a2690 |  debit | wllt_1111 |   1000 |  tok_ETH |
|         b83abefd | afb18c43 | credit | exhg_9999 |   1000 |  tok_ETH |

Notice that only 2 Local Ledger entries are made. These two entries are for moving ETH funds from
the source to the exchange wallet. Since the destination wallet is also the same exchange wallet,
no entries are made.

Also note that at the same time, the eWallet transaction still shows different `to_token` and
`from_token` values even though the local ledger performs the transaction in only one token.

This is because the eWallet transaction should still represent the original intent: to have funds
deducted in one token and arrive as another token with the help of the specified exchange agent,
while the Local Ledger entries represent the actual movement of funds.
