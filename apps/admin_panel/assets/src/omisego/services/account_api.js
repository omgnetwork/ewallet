import request from './api_service';
import { GetAccountsParams, NewAccountParams } from '../params/account_params';

export const accountAPI = {
  getAll,
  create,
};

function getAll(params, callback) {
  const { per, ...rest } = params;
  return request('account.all', JSON.stringify({ per_page: per, ...rest }), callback);
}

function create(params, callback) {
  return request('account.create', JSON.stringify(params), callback);
}
