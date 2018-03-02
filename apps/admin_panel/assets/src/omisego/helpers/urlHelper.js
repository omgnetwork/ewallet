import { ADMIN_API_BASE_URL } from '../config';

export default function buildURL(path) {
  return `${ADMIN_API_BASE_URL}/${path}`;
}
