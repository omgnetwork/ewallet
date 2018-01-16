import Cookies from 'js-cookie';
import { getCurrent } from '../../omisego/services/user_api';
import SessionActions from '../../actions/session.actions';
import sessionConstants from '../../constants/session.constants';


function getCurrentUser() {
  return (dispatch) => {
    getCurrent((err, result) => {
      if (err) {
        dispatch(SessionActions.clear());
        Cookies.remove(sessionConstants.SESSION_COOKIE);
      } else {
        dispatch(SessionActions.saveCurrentUser(result));
      }
      dispatch(SessionActions.setSync(true));
    });
  };
}

class Actions {
  static loadSession() {
    return (dispatch) => {
      dispatch(SessionActions.isSyncing());
      if (Cookies.get(sessionConstants.SESSION_COOKIE)) {
        dispatch(getCurrentUser());
      } else {
        dispatch(SessionActions.clear());
        dispatch(SessionActions.setSync(true));
      }
    };
  }
}

export default Actions;
