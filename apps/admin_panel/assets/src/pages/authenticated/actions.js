import { sessionService } from 'redux-react-session';
import { push } from 'react-router-redux';

import { logout } from '../../omisego/services/session_api';
import ErrorHandler from '../../helpers/errorHandler';
import LoadingActions from '../../actions/loading.actions';
import AlertActions from '../../actions/alert.actions';

class Actions {
  static logout() {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      logout((err, result) => { // eslint-disable-line no-unused-vars
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          sessionService
            .deleteSession()
            .then(() => {
              dispatch(push('/signin'));
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
