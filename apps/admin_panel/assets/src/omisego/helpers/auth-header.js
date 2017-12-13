import Cookies from "js-cookie";
import { OMISEGO_API_KEY } from "../config.js"

export function authHeader() {
  const authenticationToken = Cookies.get("USER-SESSION");
  if (authenticationToken) {
    return { "Authorization": "OMGAdmin " + btoa(OMISEGO_API_KEY + ":" + authenticationToken) };
  } else {
    return { "Authorization": "OMGAdmin " + btoa(OMISEGO_API_KEY) };
  }
}
