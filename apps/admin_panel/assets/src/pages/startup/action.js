import Cookies from 'js-cookie';
import { getCurrentUser, getCurrentAccount } from '../../omisego/services/self_api';
import SessionActions from '../../actions/session.actions';
import sessionConstants from '../../constants/session.constants';


function loadCurrentUser(dispatch) {
  return new Promise((resolve, reject) => {
    getCurrentUser((err, result) => {
      if (err) { reject(err); }
      dispatch(SessionActions.saveCurrentUser(result));
      resolve();
    });
  });
}

function loadCurrentAccount(dispatch) {
  return new Promise((resolve, reject) => {
    getCurrentAccount((err, result) => {
      if (err) { reject(err); }
      dispatch(SessionActions.saveCurrentAccount(result));
      resolve();
    });
  });
}

class Actions {
  static loadSession() {
    return (dispatch) => {
      dispatch(SessionActions.isSyncing());
      if (Cookies.get(sessionConstants.SESSION_COOKIE)) {
        let err;
        Promise.all([
          loadCurrentUser(dispatch).catch((error) => { err = error; }),
          loadCurrentAccount(dispatch).catch((error) => { err = error; }),
        ]).then(() => {
          if (err) {
            dispatch(SessionActions.clear());
            Cookies.remove(sessionConstants.SESSION_COOKIE);
          }
          dispatch(SessionActions.setSync(true));
        });
      } else {
        dispatch(SessionActions.clear());
        dispatch(SessionActions.setSync(true));
      }
    };
  }
}

export default Actions;
