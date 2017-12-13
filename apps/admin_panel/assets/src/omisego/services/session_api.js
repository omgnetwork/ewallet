import { request } from "./api_service";
import { LoginParams } from "../params/session_params";

export const sessionAPI = {
  login,
  logout
};

function login(email, password) {
  return request("login", new LoginParams({ email, password }).params());
}

function logout() {
  return request("logout");
}
