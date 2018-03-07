import ErrorHandler from '../../../../helpers/errorHandler';
import { getAll } from '../../../../omisego/services/transaction_api';
import LoadingActions from '../../../../actions/loading.actions';

class Actions {
  static loadTransactions(params, onSuccess) {
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
}

export default Actions;
