import { updatePassword } from '../../../omisego/services/session_api';
import { createAdmin } from '../../../omisego/services/admin_api';
import { processURL } from '../../../helpers/urlFormatter';
import ErrorHandler from '../../../helpers/errorHandler';
import LoadingActions from '../../../actions/loading.actions';

import { UPDATE_PASSWORD } from '../reset_password/ResetPasswordForm';
import { INVITATION } from '../../authenticated/setting/Setting';

class Actions {
  static updatePassword(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      updatePassword(params, (err) => {
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
      createAdmin(params, (err) => {
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
    return {
      email: params[UPDATE_PASSWORD.params.email],
      resetToken: params[UPDATE_PASSWORD.params.token],
    };
  }

  static processURLInvitationParams(location) {
    const params = processURL(location);
    return {
      email: params[INVITATION.params.email],
      resetToken: params[INVITATION.params.token],
    };
  }
}

export default Actions;
