import Cookies from 'js-cookie';
import sessionConstants from '../../constants/session.constants';
import { ADMIN_API_KEY, ADMIN_API_KEY_ID } from '../config';
import mergeHash from './helper';

function authenticationHeader(authenticated) {
  const authenticationToken = Cookies.get(sessionConstants.SESSION_COOKIE);
  if (authenticated && authenticationToken) {
    return {
      Authorization: `OMGAdmin ${btoa(`${ADMIN_API_KEY_ID}:${ADMIN_API_KEY}:${authenticationToken}`)}`,
    };
  }
  return { Authorization: `OMGAdmin ${btoa(`${ADMIN_API_KEY_ID}:${ADMIN_API_KEY}`)}` };
}

function accountHeader() {
  const currentAccountId = Cookies.get(sessionConstants.ACCOUNT_COOKIE);
  return currentAccountId ? { 'OMGAdmin-Account-ID': currentAccountId } : {};
}

export default function headers(authenticated) {
  return mergeHash(authenticationHeader(authenticated), accountHeader());
}
