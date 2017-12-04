import { request } from "./api_service";
import { LoginParams } from "../params/session_params";

export const sessionAPI = {
  login,
  logout
};

function login(username, password) {
  return request("login", new LoginParams({ username, password }).params());
}

//TODO: Refactor
function logout(authenticationHeader) {
  return request("logout", null, authenticationHeader);
}
