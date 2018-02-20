import { OMISEGO_BASE_URL } from '../config';

export default function buildURL(path) {
  console.log(OMISEGO_BASE_URL, path);
  return OMISEGO_BASE_URL + path;
}
