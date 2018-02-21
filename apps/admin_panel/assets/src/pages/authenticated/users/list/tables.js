/* eslint camelcase: 0 */
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY } = tableConstants;

const tables = (translate, datas) => ({
  headers: {
    id: { title: translate('users.table.id'), sortable: true },
    provider_user_id: { title: translate('users.table.provider_user_id'), sortable: true },
    username: { title: translate('users.table.username'), sortable: true },
    created_at: { title: translate('users.table.created_at'), sortable: true },
    updated_at: { title: translate('users.table.updated_at'), sortable: true },
  },
  contents: datas.map(({
    id, username, provider_user_id, created_at, updated_at,
  }) => ({
    id: { type: PROPERTY, value: id, shortened: true },
    username: { type: PROPERTY, value: username, shortened: false },
    provider_user_id: { type: PROPERTY, value: provider_user_id, shortened: false },
    created_at: { type: PROPERTY, value: dateFormatter.format(created_at), shortened: false },
    updated_at: { type: PROPERTY, value: dateFormatter.format(updated_at), shortened: false },
  })),
});

export default tables;
