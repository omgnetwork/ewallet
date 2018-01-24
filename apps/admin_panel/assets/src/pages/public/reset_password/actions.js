import { resetPassword } from '../../../omisego/services/session_api';
import { processURL } from '../../../helpers/urlFormatter';
import ErrorHandler from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';

class Actions {
  static resetPassword(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      resetPassword(params, (err) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess();
        }
      });
    };
  }

  static processURLParams(location) {
    const params = processURL(location);
    return { email: params.email, resetToken: params.reset_token };
  }
}

export default Actions;
