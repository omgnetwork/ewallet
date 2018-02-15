import { push } from 'react-router-redux';
import { logout } from '../../../omisego/services/session_api';
import SessionActions from '../../../actions/session.actions';
import call from '../../../actions/api.actions';

class Actions {
  static logout() {
    return call({
      service: logout,
      actions: [
        () => SessionActions.clear(),
        () => push('/signin'),
      ],
    });
  }
}

export default Actions;
