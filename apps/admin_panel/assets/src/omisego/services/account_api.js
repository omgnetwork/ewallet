import { request } from "./api_service";

export const accountAPI = {
  getAll
};

function getAll(query) {
  return request("account.all", { "q":query });
}
