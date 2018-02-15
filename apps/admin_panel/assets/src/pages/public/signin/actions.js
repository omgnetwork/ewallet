import Cookies from 'js-cookie';
import { push } from 'react-router-redux';

import { login } from '../../../omisego/services/session_api';
import SessionActions from '../../../actions/session.actions';
import sessionConstants from '../../../constants/session.constants';
import call from '../../../actions/api.actions';

class Actions {
  static login(params) {
    return call({
      params,
      service: login,
      callback: {
        onSuccess: (result) => {
          const mergedTokens = `${result.user_id}:${result.authentication_token}`;
          Cookies.set(
            sessionConstants.SESSION_COOKIE,
            mergedTokens,
            { expires: sessionConstants.SESSION_COOKIE_EXPIRATION_TIME },
          );
        },
      },
      actions: [
        () => SessionActions.setSync(false),
        () => push('/accounts'),
      ],
    });
  }
}

export default Actions;
