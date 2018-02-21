import { OMISEGO_BASE_URL } from '../config';

export default function buildURL(path) {
  return `${OMISEGO_BASE_URL}/${path}`;
}
