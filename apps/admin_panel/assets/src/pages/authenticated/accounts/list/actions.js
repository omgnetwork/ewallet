import { getAll, get } from '../../../../omisego/services/account_api';
import SessionActions from '../../../../actions/session.actions';
import call from '../../../../actions/api.actions';

export const loadAccounts = (params, onSuccess) =>
  call({
    params,
    service: getAll,
    callback: {
      onSuccess,
    },
  });

export const viewAs = accountId =>
  call({
    params: accountId,
    service: get,
    actions: [
      result => SessionActions.saveCurrentAccount(result),
    ],
  });
