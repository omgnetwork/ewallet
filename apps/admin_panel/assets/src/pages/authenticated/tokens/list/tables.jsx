/* eslint camelcase: 0 */
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY } = tableConstants;

const tables = (translate, datas) => ({
  headers: {
    id: { title: translate('tokens.table.id'), sortable: true },
    symbol: { title: translate('tokens.table.symbol'), sortable: true },
    name: { title: translate('tokens.table.name'), sortable: true },
    subunit_to_unit: { title: translate('tokens.table.subunit_to_unit'), sortable: false },
    created_at: { title: translate('tokens.table.created_at'), sortable: true },
    updated_at: { title: translate('tokens.table.updated_at'), sortable: true },
  },
  contents: datas.map(({
    id, symbol, name, subunit_to_unit, created_at, updated_at,
  }) => ({
    id: { type: PROPERTY, value: id, shortened: true },
    symbol: { type: PROPERTY, value: symbol, shortened: false },
    name: { type: PROPERTY, value: name, shortened: false },
    subunit_to_unit: {
      type: PROPERTY,
      value: subunit_to_unit,
      shortened: false,
    },
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
  })),
});

export default tables;
