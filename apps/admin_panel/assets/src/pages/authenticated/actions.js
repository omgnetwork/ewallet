import { push } from 'react-router-redux';

import { logout } from '../../omisego/services/session_api';
import ErrorHandler from '../../helpers/errorHandler';
import LoadingActions from '../../actions/loading.actions';
import SessionActions from '../../actions/session.actions';

class Actions {
  static logout() {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      logout((err, result) => {
        // eslint-disable-line no-unused-vars
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          dispatch(SessionActions.clear());
          dispatch(push('/signin'));
        }
      });
    };
  }
}

export default Actions;
