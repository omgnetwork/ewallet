import { authenticatedRequest } from './apiService'
export function getConsumptions ({ perPage, page, sort, search, searchTerms }) {
  return authenticatedRequest({
    path: '/transaction_consumption.all',
    data: {
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
    }
  })
}
export function approveConsumptionById (id) {
  return authenticatedRequest({
    path: '/transaction_consumption.approve',
    data: { id }
  })
}
export function rejectConsumptionById (id) {
  return authenticatedRequest({
    path: '/transaction_consumption.reject',
    data: { id }
  })
}

export function getConsumptionById (id) {
  return authenticatedRequest({
    path: '/transaction_consumption.get',
    data: { id }
  })
}
