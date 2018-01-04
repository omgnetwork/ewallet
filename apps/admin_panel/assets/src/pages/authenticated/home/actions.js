import { sessionService } from 'redux-react-session';
import { push } from 'react-router-redux';

import { sessionAPI } from '../../../omisego/services';
import { handleAPIError } from '../../../helpers/errorHandler';
import { loadingActions, alertActions } from '../../../actions';

class Actions {
  static logout() {
    return (dispatch) => {
      dispatch(loadingActions.showLoading());
      sessionAPI.logout((err, result) => { // eslint-disable-line no-unused-vars
        dispatch(loadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          sessionService
            .deleteSession()
            .then(() => {
              dispatch(push('/signin'));
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
