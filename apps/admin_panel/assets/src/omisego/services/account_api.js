import { request } from "./api_service";

export const accountAPI = {
  getAll
};

function getAll() {
  return request("account.all");
}
