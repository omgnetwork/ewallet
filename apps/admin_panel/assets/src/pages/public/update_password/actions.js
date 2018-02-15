import { updatePassword } from '../../../omisego/services/session_api';
import { createAdmin } from '../../../omisego/services/admin_api';
import { processURL } from '../../../helpers/urlFormatter';
import call from '../../../actions/api.actions';
import SERIALIZER from '../../../helpers/serializer';

import { UPDATE_PASSWORD } from '../reset_password/ResetPasswordForm';
import { INVITATION } from '../../authenticated/setting/Setting';

class Actions {
  static updatePassword(params, onSuccess) {
    return call({
      params,
      service: updatePassword,
      callback: {
        onSuccess: SERIALIZER.NOTHING(onSuccess),
      },
    });
  }

  static createNewAdmin(params, onSuccess) {
    return call({
      params,
      service: createAdmin,
      callback: {
        onSuccess: SERIALIZER.NOTHING(onSuccess),
      },
    });
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
