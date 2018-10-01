# Advanced Filtering

When fetching transactions, users, and other records from the eWallet, you can perform various filters on your request. This is done by passing `"match_all"` and/or `"match_any"` in your `/*.all` request bodies. Consult the API documentations for which endpoints support advanced filtering.

## Specifying the matching operation

You can specify the filter to match all provided conditions, or match at least one:

- `match_all` requires that all provided conditions are matched for a record to be returned
- `match_any` requires that at least one of the provided conditions is matched for a record to be returned

Both operations can be used in conjunction by providing both `match_all` and `match_any` in the request body.

## Specifying the conditions

Each condition must consist of the following required parameters:

- `field`: The field name to filter from.
- `comparator`: The operator to use for filtering. Such as `eq`, `neq`, etc.
- `value`: The value to use for filtering.

### Filtering by a relation

The `field` parameter also supports filtering of the record's direct relations. This is done by separating the relation's name and its field with a dot. For example, `from_user.username` refers to the `username` field in the `from_user` relation. Up to 5 unique associations can be filtered.

### Supported comparators

- `eq` (is equal to)
- `neq` (is not equal to)
- `lt` (is less than)
- `lte` (is less than or equal to)
- `gt` (is greater than)
- `gte` (is greater than or equal to)
- `contains` (contains)
- `starts_with` (starts with)

## Example

Consider this example below. These request parameters will filter for transactions that:

- The transaction's status is `confirmed`
- The transaction came from (`from_user`) _or_ went to (`to_user`) the user with username `"alice"`

```json
POST /transaction.all
{
  "match_all": [
    {
      "field": "status",
      "comparator": "eq",
      "value": "confirmed"
    }
  ],
  "match_any": [
    {
      "field": "from_user.username",
      "comparator": "eq",
      "value": "alice"
    },
    {
      "field": "to_user.username",
      "comparator": "eq",
      "value": "alice"
    }
  ]
}
```


