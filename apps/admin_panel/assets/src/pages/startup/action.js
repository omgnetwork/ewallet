import Cookies from 'js-cookie';
import { getCurrentUser, getCurrentAccount } from '../../omisego/services/self_api';
import { get } from '../../omisego/services/account_api';
import SessionActions from '../../actions/session.actions';
import sessionConstants from '../../constants/session.constants';
import { accountErrors } from '../../constants/error.constants';

function loadCurrentUser(dispatch) {
  return new Promise((resolve, reject) => getCurrentUser()
    .then((result) => {
      dispatch(SessionActions.saveCurrentUser(result));
      resolve();
    })
    .catch(error => reject(error)));
}

function loadCurrentAccount(dispatch) {
  function processAccountId() {
    const path = document.location.pathname;
    if (/\/a\/.*(?=\/)/.test(path)) {
      return path.split('/')[2];
    }
    return Cookies.get(sessionConstants.ACCOUNT_COOKIE);
  }
  return new Promise((resolve, reject) => {
    function saveAccount(account) {
      dispatch(SessionActions.saveCurrentAccount(account));
      resolve();
    }
    function loadFromToken() {
      getCurrentAccount()
        .then((account) => {
          saveAccount(account);
          resolve();
        })
        .catch(err => reject(err));
    }
    function loadFromId(accountId) {
      get(accountId)
        .then((account) => {
          saveAccount(account);
        })
        .catch((err) => {
          if (err.code === accountErrors.idNotFound) {
            loadFromToken();
          } else {
            reject(err);
          }
        });
    }
    const accountId = processAccountId();
    accountId ? loadFromId(accountId) : loadFromToken(); // eslint-disable-line
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
