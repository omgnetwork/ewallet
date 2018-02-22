/* eslint camelcase: 0 */
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY } = tableConstants;

const tables = (translate, datas, handleActions) => ({
  headers: {
    id: { title: translate('users.table.id'), sortable: true },
    name: { title: translate('accounts.table.name'), sortable: true },
    description: { title: translate('accounts.table.description'), sortable: true },
    created_at: { title: translate('accounts.table.created_at'), sortable: true },
    updated_at: { title: translate('accounts.table.updated_at'), sortable: true },
    actions: { title: translate('accounts.table.actions'), sortable: false },
  },
  contents: datas.map(({
    id, name, description, created_at, updated_at,
  }) => ({
    id: { type: PROPERTY, value: id, shortened: true },
    name: { type: PROPERTY, value: name, shortened: false },
    description: { type: PROPERTY, value: description, shortened: false },
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
    action: {
      type: tableConstants.ACTIONS,
      value: [{
        title: translate('accounts.table.view_as'),
        click: () => handleActions.viewAs(id),
      }],
      shortened: false,
    },
  })),
});

export default tables;
