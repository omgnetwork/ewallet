import { create } from '../../../../omisego/services/user_api';
import call from '../../../../actions/api.actions';

class Actions {
  static createUser(params, onSuccess) {
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
