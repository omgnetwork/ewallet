import { request } from "./api_service";
import { GetAccountsParams, NewAccountParams } from "../params/account_params";

export const accountAPI = {
  getAll,
  create
};

function getAll(query, page, per) {
  return request("account.all", new GetAccountsParams({ query, page, per }).params());
}

function create(name, description) {
  return request("account.create", new NewAccountParams({ name, description }).params());
}
