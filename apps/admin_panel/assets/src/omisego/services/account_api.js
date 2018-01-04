import request from './api_service';
import { GetAccountsParams, NewAccountParams } from '../params/account_params';

export const accountAPI = {
  getAll,
  create,
};

function getAll(params, callback) {
  const { currentPage, ...rest } = params;
  return request('account.all', JSON.stringify({ current_page: currentPage, ...rest }), callback);
}

function create(params, callback) {
  return request('account.create', JSON.stringify(params), callback);
}
