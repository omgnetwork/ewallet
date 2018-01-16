import Cookies from 'js-cookie';
import { OMISEGO_API_KEY, OMISEGO_API_KEY_ID } from '../config';

export default function authHeader() {
  const authenticationToken = Cookies.get('session');
  if (authenticationToken) {
    return { Authorization: `OMGAdmin ${btoa(`${OMISEGO_API_KEY_ID}:${OMISEGO_API_KEY}:${authenticationToken}`)}` };
  }
  return { Authorization: `OMGAdmin ${btoa(`${OMISEGO_API_KEY_ID}:${OMISEGO_API_KEY}`)}` };
}
