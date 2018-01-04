import { handleAPIError } from '../../../../helpers/errorHandler';
import { accountAPI } from '../../../../omisego/services';
import { loadingActions } from '../../../../actions/global.actions';

class Actions {
  static createAccount(params, onSuccess) {
    return (dispatch) => {
      dispatch(loadingActions.showLoading());
      accountAPI.create(params, (err, result) => {
        dispatch(loadingActions.hideLoading());
        if (err) { handleAPIError(dispatch, err); } else {
          onSuccess(result);
        }
      });
    };
  }
}

export default Actions;
