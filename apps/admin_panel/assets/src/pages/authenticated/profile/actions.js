import ErrorHandler from '../../../helpers/errorHandler';
import { uploadAvatar } from '../../../omisego/services/admin_api';
import { getUser } from '../../../omisego/services/user_api';
import LoadingActions from '../../../actions/loading.actions';

export default class Actions {
  static uploadAvatar(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      uploadAvatar(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(result);
        }
      });
    };
  }

  static getUser(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      getUser(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(result.data);
        }
      });
    };
  }
}
