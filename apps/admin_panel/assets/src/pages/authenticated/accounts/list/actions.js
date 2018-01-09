import { handleAPIError } from '../../../../helpers/errorHandler';
import { getAll } from '../../../../omisego/services/account_api';
import LoadingActions from '../../../../actions/loading.actions';

class Actions {
  static loadAccounts(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      getAll(params, (err, results) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          onSuccess(results.data, results.pagination);
        }
      });
    };
  }
}

export default Actions;
