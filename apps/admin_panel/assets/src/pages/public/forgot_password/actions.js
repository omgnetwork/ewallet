import { forgotPassword } from '../../../omisego/services/session_api';
import ErrorHandler from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';

class Actions {
  static forgotPassword(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      forgotPassword(params, (err) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess();
        }
      });
    };
  }
}

export default Actions;
