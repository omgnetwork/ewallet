import filters from './filters'

export const FILTER_MAP = [
  {
    title: 'Transfer From',
    icon: 'Option-Horizontal',
    code: 'transfer-from',
    page: 'transaction',
    height: 110,
    component: filters.TransferFrom
  },
  {
    title: 'Transfer To',
    icon: 'Option-Horizontal',
    code: 'transfer-to',
    page: 'transaction',
    height: 110,
    component: filters.TransferTo
  },
  {
    title: 'Specify Target',
    icon: 'Option-Horizontal',
    code: 'specify-target',
    page: 'transaction',
    height: 110,
    component: filters.SpecifyTarget
  },
  {
    title: 'Date & Time',
    icon: 'Option-Horizontal',
    code: 'date-time',
    page: 'transaction'
  },
  {
    title: 'Status',
    icon: 'Option-Horizontal',
    code: 'status',
    page: 'transaction'
  },
  {
    title: 'Wallet Type',
    icon: 'Option-Horizontal',
    code: 'wallet-type',
    page: 'transaction',
    height: 110,
    component: filters.WalletType
  },
  {
    title: 'Request',
    icon: 'Option-Horizontal',
    code: 'request',
    page: 'transaction',
    height: 110,
    component: filters.Request
  }
]
