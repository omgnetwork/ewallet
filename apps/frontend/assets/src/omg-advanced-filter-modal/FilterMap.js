import filters from './filters'

export const FILTER_MAP = [
  {
    title: 'Transfer From',
    icon: 'Option-Horizontal',
    code: 'from_account.id',
    page: 'transaction',
    height: 110,
    component: filters.TransferFrom,
    default: false
  },
  {
    title: 'Transfer To',
    icon: 'Option-Horizontal',
    code: 'to_address',
    page: 'transaction',
    height: 110,
    component: filters.TransferTo,
    default: false
  },
  {
    title: 'Specify Target',
    icon: 'Option-Horizontal',
    code: 'specify-target',
    page: 'transaction',
    height: 110,
    component: filters.SpecifyTarget,
    default: false
  },
  {
    title: 'Date & Time',
    icon: 'Option-Horizontal',
    code: 'date-time',
    page: 'transaction',
    height: 205,
    component: filters.DateTime,
    default: true
  },
  {
    title: 'Status',
    icon: 'Option-Horizontal',
    code: 'status',
    page: 'transaction',
    height: 165,
    component: filters.Status,
    default: true
  },
  {
    title: 'Wallet Type',
    icon: 'Option-Horizontal',
    code: 'wallet-type',
    page: 'transaction',
    height: 110,
    component: filters.WalletType,
    default: false
  },
  {
    title: 'Request',
    icon: 'Option-Horizontal',
    code: 'request',
    page: 'transaction',
    height: 110,
    component: filters.Request,
    default: false
  }
]
