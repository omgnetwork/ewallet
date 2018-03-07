import ErrorHandler from '../../../../helpers/errorHandler';
import { create } from '../../../../omisego/services/user_api';
import LoadingActions from '../../../../actions/loading.actions';

class Actions {
  static createUser(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      create(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) { ErrorHandler.handleAPIError(dispatch, err); } else {
          onSuccess(result);
        }
      });
    };
  }
}

export default Actions;
