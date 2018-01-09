import { sessionService } from 'redux-react-session';
import { push } from 'react-router-redux';

import { login } from '../../../omisego/services/session_api';
import { handleAPIError } from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';
import AlertActions from '../../../actions/alert.actions';

class Actions {
  static login(params) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      login(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
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
              dispatch(AlertActions.error(error));
            });
        }
      });
    };
  }
}

export default Actions;
