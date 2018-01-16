import sessionConstants from '../constants/session.constants';

class SessionActions {
  static saveCurrentUser(user) {
    return { type: sessionConstants.SAVE_CURRENT_USER, user };
  }

  static clear() {
    return { type: sessionConstants.CLEAR };
  }

  static isSyncing() {
    return { type: sessionConstants.IS_SYNCING };
  }

  static setSync(sync) {
    return { type: sessionConstants.SET_SYNCED, sync };
  }
}

export default SessionActions;
