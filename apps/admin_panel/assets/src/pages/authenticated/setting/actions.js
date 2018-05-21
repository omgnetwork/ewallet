import ErrorHandler from '../../../helpers/errorHandler';
import { assignMember, inviteMember, unassignMember, listMembers, updateMember, updateAccountInfo, uploadAvatar } from '../../../omisego/services/setting_api';
import LoadingActions from '../../../actions/loading.actions';
import { getAll } from '../../../omisego/services/admin_api';
import SessionActions from '../../../actions/session.actions';
import SERIALIZER from '../../../helpers/serializer';
import call from '../../../actions/api.actions';

export default class Actions {
  static updateAccount(params, onSuccess) {
    return call({
      params,
      service: updateAccountInfo,
      callback: {
        onSuccess: SERIALIZER.UPDATE_ACCOUNT(onSuccess),
      },
      actions: [
        result => SessionActions.saveCurrentAccount(result),
      ],
    });
  }

  static assignMember(params, onSuccess) {
    return call({
      params,
      service: assignMember,
      callback: {
        onSuccess: SERIALIZER.DATA(onSuccess),
      },
    });
  }

  static inviteMember(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      inviteMember(params)
        .then(() => dispatch(LoadingActions.hideLoading()))
        .then(() => onSuccess(params))
        .catch(err => ErrorHandler.handleAPIError(dispatch, err));
    };
  }

  static updateMember(params, onSuccess) {
    return call({
      params,
      service: updateMember,
      callback: {
        onSuccess: SERIALIZER.DATA(onSuccess),
      },
    });
  }

  static searchUsers(params, onSuccess) {
    return call({
      params,
      service: getAll,
      callback: {
        onSuccess: SERIALIZER.SEARCH_USERS(onSuccess),
      },
    });
  }

  static listMembers(params, onSuccess) {
    console.log(params, '#################');
    return call({
      params,
      service: listMembers,
      callback: {
        onSuccess: SERIALIZER.LIST_MEMBER(onSuccess),
      },
    });
  }

  static unassignMember(params, onSuccess) {
    return call({
      params,
      service: unassignMember,
      callback: {
        onSuccess: SERIALIZER.DATA(onSuccess),
      },
    });
  }

  static uploadAvatar(params, onSuccess) {
    return call({
      params,
      service: uploadAvatar,
      callback: {
        onSuccess: SERIALIZER.DATA(onSuccess),
      },
    });
  }

  static updateAccountAndAvatar(params, onSuccess, onFailed) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      Promise.all([
        uploadAvatar(params.uploadAvatar),
        updateAccountInfo(params.updateAccount),
      ]).then(([resultUploadAvatar, resultUpdateAccountInfo]) => {
        dispatch(LoadingActions.hideLoading());
        dispatch(SessionActions.saveCurrentAccount({
          ...resultUploadAvatar,
          avatar: resultUploadAvatar.avatar,
          name: resultUpdateAccountInfo.name,
        }));
        const result = {
          uploadAvatar: resultUploadAvatar,
          updateAccount: resultUpdateAccountInfo,
        };
        onSuccess(result);
      }).catch((e) => {
        onFailed(e);
      });
    };
  }
}
