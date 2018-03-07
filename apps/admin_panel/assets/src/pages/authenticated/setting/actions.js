import ErrorHandler from '../../../helpers/errorHandler';
import { assignMember, inviteMember, unassignMember, listMembers, updateMember, updateAccountInfo } from '../../../omisego/services/setting_api';
import LoadingActions from '../../../actions/loading.actions';
import { getAll } from '../../../omisego/services/admin_api';
import SessionActions from '../../../actions/session.actions';

export default class Actions {
  static updateAccount(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      updateAccountInfo(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(result);
          dispatch(SessionActions.saveCurrentAccount(result));
        }
      });
    };
  }

  static assignMember(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      assignMember(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(result.data);
        }
      });
    };
  }

  static inviteMember(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      inviteMember(params, (err, result) => { // eslint-disable-line no-unused-vars
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(params);
        }
      });
    };
  }

  static updateMember(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      updateMember(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          onSuccess(result.data);
        }
      });
    };
  }

  static searchUsers(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      getAll(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          const members = result.data.map(member => ({
            id: member.id,
            username: member.username,
            email: member.email,
          }));
          onSuccess(members);
        }
      });
    };
  }

  static listMembers(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      listMembers(params, (err, result) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          ErrorHandler.handleAPIError(dispatch, err);
        } else {
          const members = result.data.map(member => ({
            id: member.id,
            username: member.username,
            email: member.email,
            status: member.status,
            accountRole: member.account_role,
          }));
          onSuccess(members);
        }
      });
    };
  }

  static unassignMember(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      unassignMember(params, (err, result) => {
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
