import Cookies from 'js-cookie';
import sessionConstants from '../../constants/session.constants';
import { OMISEGO_API_KEY, OMISEGO_API_KEY_ID } from '../config';
import mergeHash from './helper';

function authenticationHeader() {
  const authenticationToken = Cookies.get(sessionConstants.SESSION_COOKIE);
  if (authenticationToken) {
    return {
      Authorization: `OMGAdmin ${btoa(`${OMISEGO_API_KEY_ID}:${OMISEGO_API_KEY}:${authenticationToken}`)}`,
    };
  }
  return { Authorization: `OMGAdmin ${btoa(`${OMISEGO_API_KEY_ID}:${OMISEGO_API_KEY}`)}` };
}

function accountHeader() {
  const currentAccountId = Cookies.get(sessionConstants.ACCOUNT_COOKIE);
  return currentAccountId ? { 'OMGAdmin-Account-ID': currentAccountId } : {};
}

export default function headers() {
  return mergeHash(authenticationHeader(), accountHeader());
}
