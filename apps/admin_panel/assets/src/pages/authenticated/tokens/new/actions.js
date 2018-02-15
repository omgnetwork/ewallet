import { create } from '../../../../omisego/services/token_api';
import call from '../../../../actions/api.actions';

class Actions {
  static createToken(params, onSuccess) {
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
