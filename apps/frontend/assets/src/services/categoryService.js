import { authenticatedRequest } from './apiService'

export function getCategories ({ perPage, sort, search, ...rest }) {
  return authenticatedRequest({
    path: '/category.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      ...rest
    }
  })
}

export function getCategory ({ id }) {
  return authenticatedRequest({
    path: '/category.all',
    data: {
      id
    }
  })
}
export function createCategory ({ name, description, accountId }) {
  return authenticatedRequest({
    path: '/category.create',
    data: {
      name,
      description,
      account_ids: [accountId]
    }
  })
}
