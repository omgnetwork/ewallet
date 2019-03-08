# Pagination

When fetching multiple records from the eWallet, you need to specify after which record you want to retrieve the next portion of records. You can also specify options to customize the result. Consult the API documentations for which endpoints support pagination.

## Structure

Every field is `optional`, meaning that sending `{}` is valid.


| Field 	| Type 	| Default 	| Description 	|
|-------------	|:-------:	|:------------:	|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| start_after 	| any 	| `null` 	| Specify after which record you want to receive a set of records.  This value need to be associated with `start_by`.  Set `null` or `nil` to retrieve records from the beginning. 	|
| start_by 	| string 	| `id` 	| Specify attribute to be associated with start_after. 	|
| per_page 	| integer 	| `10` 	| Specify the total records of the page to be retrieved. 	|
| sort_by 	| string 	| `created_at` 	| Specify sort attribute. 	|
| sort_dir 	| string 	| `desc` 	| Specify sort direction. The value can be either `asc` or `desc`. 	|
| search_term 	| string 	| `null` 	| Specify the keyword to be contained in any attribute of the record (Full-text search). 	|

If the options above doesn't work for you, you might want to see [Advance Filtering](https://github.com/omisego/ewallet/blob/master/docs/guides/advanced_filtering.md) guide.

## Example

Let's say we have 10 `accounts` with the following ids:

`acc_01`, `acc_02`, ... , `acc_10`

### Retrieve first 5 records

Full
```json
{
  "start_after": null,
  "start_by": "id",
  "per_page": 5,
  "sort_by": "created_at",
  "sort_dir": "desc",
  "search_term": null
}
```


Short
```json
{
  "per_page": 5
}
```

### Retrieve`acc_04` to `acc_10`

Full
```json
{
  "start_after": "acc_03",
  "start_by": "id",
  "per_page": 10,
  "sort_by": "created_at",
  "sort_dir": "desc",
  "search_term": null
}
```

Short
```json
{
  "start_after": "acc_03"
}
```
