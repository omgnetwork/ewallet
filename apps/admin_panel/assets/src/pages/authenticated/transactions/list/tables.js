/* eslint camelcase: 0 */
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const tables = (translate, datas) => ({
  headers: {
    id: { title: translate('transactions.table.id'), sortable: true },
    amount: { title: translate('transactions.table.amount'), sortable: false },
    token: { title: translate('transactions.table.token'), sortable: false },
    from: { title: translate('transactions.table.from'), sortable: true },
    to: { title: translate('transactions.table.to'), sortable: true },
    idempotency_token: { title: translate('transactions.table.idempotency_token'), sortable: true },
    status: { title: translate('transactions.table.status'), sortable: true },
    created_at: { title: translate('transactions.table.created_at'), sortable: true },
  },
  contents: datas.map(({
    id, amount, minted_token, from, to, idempotency_token, status, created_at,
  }) => ({
    id: { type: tableConstants.PROPERTY, value: id, shortened: true },
    amount: {
      type: tableConstants.PROPERTY,
      value: amount / minted_token.subunit_to_unit,
      shortened: false,
    },
    token: { type: tableConstants.PROPERTY, value: minted_token.id, shortened: true },
    from: { type: tableConstants.PROPERTY, value: from, shortened: true },
    to: { type: tableConstants.PROPERTY, value: to, shortened: true },
    idempotency_token: {
      type: tableConstants.PROPERTY,
      value: idempotency_token,
      shortened: true,
    },
    status: { type: tableConstants.PROPERTY, value: status, shortened: false },
    created_at: {
      type: tableConstants.PROPERTY,
      value: dateFormatter.format(created_at),
      shortened: false,
    },
  })),
});

export default tables;
