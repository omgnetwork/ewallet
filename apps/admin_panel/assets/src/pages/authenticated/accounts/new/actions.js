import { create } from '../../../../omisego/services/account_api';
import call from '../../../../actions/api.actions';

const createAccount = (params, onSuccess) =>
  call({
    params,
    service: create,
    callback: {
      onSuccess,
    },
  });

export default createAccount;
