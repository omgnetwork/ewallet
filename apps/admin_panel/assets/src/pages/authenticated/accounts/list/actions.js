import ErrorHandler from '../../../../helpers/errorHandler';
import { getAll, get } from '../../../../omisego/services/account_api';
import LoadingActions from '../../../../actions/loading.actions';
import SessionActions from '../../../../actions/session.actions';

class Actions {
  static loadAccounts(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      getAll(params, (err, results) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(results.data, results.pagination);
        }
      });
    };
  }

  static viewAs(accountId) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      get(accountId, (err, results) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          dispatch(SessionActions.saveCurrentAccount(results));
        }
      });
    };
  }
}

export default Actions;
