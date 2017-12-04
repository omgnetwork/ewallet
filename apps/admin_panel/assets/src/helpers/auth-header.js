import Cookies from "js-cookie";

export function authHeader() {
  const authenticationToken = Cookies.get("USER-SESSION");
  if (authenticationToken) {
    return { "Authorization": "OMGAdmin " + authenticationToken };
  } else {
    return {};
  }
}
