import { handleAPIError } from '../../../../helpers/errorHandler';
import { create } from '../../../../omisego/services/token_api';
import LoadingActions from '../../../../actions/loading.actions';

class Actions {
  static createToken(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      create(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          onSuccess(result);
        }
      });
    };
  }
}

export default Actions;
