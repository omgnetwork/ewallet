import filters from './filters'

export const FILTER_MAP = [
  {
    title: 'Transfer From',
    key: 'transfer-from',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.TransferFrom,
    default: false,
    matchAll: [
      {
        field: 'from_account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Transfer To',
    key: 'transfer-to',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.TransferTo,
    default: false,
    matchAll: [
      {
        field: 'to_account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Target',
    key: 'specify-target',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.SpecifyTarget,
    default: false,
    matchAny: [
      {
        field: 'to_account.id',
        comparator: 'contains'
      },
      {
        field: 'from_account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Date & Time',
    key: 'date-time',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 205,
    component: filters.DateTime,
    default: true
  },
  {
    title: 'Status',
    key: 'status',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 165,
    component: filters.Status,
    default: true
  },
  {
    title: 'Wallet Type',
    key: 'wallet-type',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.WalletType,
    default: false
  },
  {
    title: 'Request',
    key: 'request',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.Request,
    default: false
  }
]
