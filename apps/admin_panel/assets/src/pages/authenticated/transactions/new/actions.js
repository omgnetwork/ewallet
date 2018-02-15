import { create } from '../../../../omisego/services/transaction_api';
import call from '../../../../actions/api.actions';

class Actions {
  static createAccount(params, onSuccess) {
    return call({
      params,
      service: create,
      callback: {
        onSuccess,
      },
    });
  }
}

export default Actions;
