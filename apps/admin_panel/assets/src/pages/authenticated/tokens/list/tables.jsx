/* eslint camelcase: 0 */
import React from 'react';
import FA from 'react-fontawesome';
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY } = tableConstants;

const tables = (translate, datas) => ({
  headers: {
    id: { title: translate('tokens.table.id'), sortable: true },
    symbol: { title: translate('tokens.table.symbol'), sortable: true },
    name: { title: translate('tokens.table.name'), sortable: true },
    subunit_to_unit: { title: translate('tokens.table.subunit_to_unit'), sortable: true },
    account: { title: translate('tokens.table.account'), sortable: true },
    created_at: { title: translate('tokens.table.created_at'), sortable: true },
    updated_at: { title: translate('tokens.table.updated_at'), sortable: true },
    locked: { title: translate('tokens.table.locked'), sortable: true },
  },
  contents: datas.map(({
    id, symbol, name, subunit_to_unit, account, created_at, updated_at, locked,
  }) => ({
    id: { type: PROPERTY, value: id, shortened: true },
    symbol: { type: PROPERTY, value: symbol, shortened: false },
    name: { type: PROPERTY, value: name, shortened: false },
    subunit_to_unit: {
      type: PROPERTY,
      value: subunit_to_unit,
      shortened: false,
    },
    account: { type: PROPERTY, value: account, shortened: false },
    created_at: {
      type: PROPERTY,
      value: dateFormatter.format(created_at),
      shortened: false,
    },
    updated_at: {
      type: PROPERTY,
      value: dateFormatter.format(updated_at),
      shortened: false,
    },
    locked: {
      type: PROPERTY,
      value: locked ? <FA name="lock" /> : <FA name="unlock" />,
      shortened: false,
    },
  })),
});

export default tables;
