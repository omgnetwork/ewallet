import { handleAPIError } from '../../../../helpers/errorHandler';
import { accountAPI } from '../../../../omisego/services';
import { loadingActions } from '../../../../actions/global.actions';
import { PAGINATION } from '../../../../helpers/constants';

class Actions {
  static loadAccounts(params, onSuccess) {
    return (dispatch) => {
      dispatch(loadingActions.showLoading());
      accountAPI.getAll(params, (err, results) => {
        dispatch(loadingActions.hideLoading());
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
