import sessionConstants from '../constants/session.constants';

export default function session(state =
  { currentUser: null, isSynced: false, isSyncing: false }, action) {
  switch (action.type) {
    case sessionConstants.SAVE_CURRENT_USER:
      return {
        ...state,
        currentUser: action.user,
      };
    case sessionConstants.CLEAR:
      return {
        ...state,
        currentUser: null,
      };
    case sessionConstants.IS_SYNCING:
      return {
        ...state,
        isSyncing: true,
      };
    case sessionConstants.SET_SYNCED:
      return {
        ...state,
        isSyncing: false,
        isSynced: action.sync,
      };
    default:
      return state;
  }
}
