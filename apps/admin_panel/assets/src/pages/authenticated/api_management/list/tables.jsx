/* eslint camelcase: 0 */
import React from 'react';
import FA from 'react-fontawesome';
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const { PROPERTY, ACTIONS } = tableConstants;

const tables = (translate, datas, handleActions) => ({
  headers: {
    id: { title: translate('api-management.table.id'), sortable: true },
    key: { title: translate('api-management.table.key'), sortable: true },
    owner_app: { title: translate('api-management.table.owner_app'), sortable: true },
    created_at: { title: translate('api-management.table.created_at'), sortable: true },
    updated_at: { title: translate('api-management.table.updated_at'), sortable: true },
    active: { title: translate('api-management.table.active'), sortable: false },
    actions: { title: translate('api-management.table.actions'), sortable: false },
  },
  contents: datas.map(({
    id, key, owner_app, created_at, updated_at, deleted_at,
  }) => ({
    id: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-gray' : '',
      value: id,
      shortened: true,
    },
    key: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-gray' : '',
      value: key,
      shortened: true,
    },
    owner_app: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-gray' : '',
      value: owner_app,
      shortened: false,
    },
    created_at: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-gray' : '',
      value: dateFormatter.format(created_at),
      shortened: false,
    },
    updated_at: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-gray' : '',
      value: dateFormatter.format(updated_at),
      shortened: false,
    },
    active: {
      type: PROPERTY,
      className: deleted_at ? 'omg-table-content-row__td-red' : 'omg-table-content-row__td-green',
      value: deleted_at ? <FA name="times" /> : <FA name="check" />,
      shortened: false,
    },
    action: {
      type: ACTIONS,
      className: deleted_at ? 'omg-table-content-row__td-gray' : 'omg-table-content-row__td-red',
      value: [{
        disabled: deleted_at !== null,
        title: deleted_at ? translate('api-management.table.disabled') : translate('api-management.table.disable'),
        click: handleCallback => handleActions.delete(id, handleCallback.onSuccess),
        dialogText: {
          title: translate('api-management.table.dialog.delete.title'),
          body: translate('api-management.table.dialog.delete.body', { api_key: id }),
          ok: translate('api-management.table.dialog.delete.ok'),
          cancel: translate('api-management.table.dialog.delete.cancel'),
        },
        shouldConfirm: true,
      }],
      shortened: false,
    },
  })),
});

export default tables;
