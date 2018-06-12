import { authenticatedRequest, authenticatedMultipartRequest } from './apiService'
export function getAllAccounts ({ per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/account.all',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function createAccount ({ name, description, category }) {
  return authenticatedRequest({
    path: '/account.create',
    data: { name, description, category_ids: [category] }
  })
}

export function getAccountById (id) {
  return authenticatedRequest({
    path: '/account.get',
    data: { id }
  })
}

export function uploadAccountAvatar ({ accountId, avatar }) {
  const formData = new window.FormData()
  formData.append('id', accountId)
  formData.append('avatar', avatar)
  return authenticatedMultipartRequest({
    path: '/account.upload_avatar',
    data: formData
  })
}
