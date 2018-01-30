import { resetPassword } from '../../../omisego/services/session_api';
import createNewAdmin from '../../../omisego/services/create_new_admin_api';
import { processURL } from '../../../helpers/urlFormatter';
import ErrorHandler from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';
import { invitationConst } from '../../../omisego/services/setting_api';

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

  static createNewAdmin(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      createNewAdmin(params, (err) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess();
        }
      });
    };
  }

  static processURLResetPWParams(location) {
    const params = processURL(location);
    return { email: params.email, resetToken: params.reset_token };
  }

  static processURLInvitationParams(location) {
    const params = processURL(location);
    const result = Object.keys(invitationConst.params).reduce((previousValue, currentValue) => ({
      ...previousValue,
      currentValue: params[currentValue],
    }), {});

    result.resetToken = result.token;
    return result;
  }
}

export default Actions;
