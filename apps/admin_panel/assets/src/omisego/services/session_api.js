import request from './api_service';
import LoginParams from '../params/session_params';

export const sessionAPI = {
  login,
  logout,
};

function login(params, callback) {
  return request('login', JSON.stringify(params), callback);
}

function logout(callback) {
  return request('logout', null, callback);
}
