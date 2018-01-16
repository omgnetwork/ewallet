import Cookies from 'js-cookie';
import { push } from 'react-router-redux';

import { login } from '../../../omisego/services/session_api';
import ErrorHandler from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';
import SessionActions from '../../../actions/session.actions';
import sessionConstants from '../../../constants/session.constants';

class Actions {
  static login(params) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      login(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          const mergedTokens = `${result.user_id}:${result.authentication_token}`;
          Cookies.set(
            sessionConstants.SESSION_COOKIE,
            mergedTokens,
            { expires: sessionConstants.SESSION_COOKIE_EXPIRATION_TIME },
          );
          dispatch(SessionActions.setSync(false));
          dispatch(push('/accounts'));
        }
      });
    };
  }
}

export default Actions;
