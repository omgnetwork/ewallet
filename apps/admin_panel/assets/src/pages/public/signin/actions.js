import { sessionService } from 'redux-react-session';
import { push } from 'react-router-redux';

import { sessionAPI } from '../../../omisego/services';
import { handleAPIError } from '../../../helpers/errorHandler';
import { loadingActions, alertActions } from '../../../actions';

class Actions {
  static login(params) {
    return (dispatch) => {
      dispatch(loadingActions.showLoading());
      sessionAPI.login(params, (err, result) => {
        dispatch(loadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          const mergedTokens = `${result.user_id}:${result.authentication_token}`;
          sessionService
            .saveSession(mergedTokens)
            .then(() => {
              dispatch(push('/accounts'));
            })
            .catch((error) => {
              dispatch(alertActions.error(error));
            });
        }
      });
    };
  }
}

export default Actions;
