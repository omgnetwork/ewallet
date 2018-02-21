import { create } from '../../../../omisego/services/api_management_api';
import call from '../../../../actions/api.actions';

class Actions {
  static create(params, onSuccess) {
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
