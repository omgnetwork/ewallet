/* eslint camelcase: 0 */
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY } = tableConstants;

const tables = (translate, datas) => ({
  headers: {
    id: { title: translate('admins.table.id'), sortable: true },
    email: { title: translate('admins.table.email'), sortable: true },
    created_at: { title: translate('admins.table.created_at'), sortable: true },
    updated_at: { title: translate('admins.table.updated_at'), sortable: true },
  },
  contents: datas.map(({
    id, email, created_at, updated_at,
  }) => ({
    id: { type: PROPERTY, value: id, shortened: true },
    email: { type: PROPERTY, value: email, shortened: false },
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
