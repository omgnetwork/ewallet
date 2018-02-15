import { uploadAvatar } from '../../../omisego/services/admin_api';
import { getUser } from '../../../omisego/services/user_api';
import SessionActions from '../../../actions/session.actions';
import call from '../../../actions/api.actions';

export default class Actions {
  static uploadAvatar(params, onSuccess, onFail) {
    return call({
      params,
      service: uploadAvatar,
      callback: {
        onSuccess,
        onFail,
      },
      actions: [
        result => SessionActions.saveCurrentUser(result),
      ],
    });
  }

  static getUser(params, onSuccess) {
    return call({
      params,
      service: getUser,
      callback: {
        onSuccess,
      },
    });
  }
}
