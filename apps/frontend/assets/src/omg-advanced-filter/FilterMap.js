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
    default: true,
    matchAll: [
      {
        field: 'inserted_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'inserted_at',
        comparator: 'lte',
        value: '{{ endDate }}'
      }
    ]
  },
  {
    title: 'Status',
    key: 'status',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 165,
    component: filters.Status,
    default: true,
    matchAny: [
      {
        field: 'status',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Wallet Type',
    key: 'wallet-type',
    icon: 'Option-Horizontal',
    // page: 'transaction', // wait for blockchain integration to enable
    height: 110,
    component: filters.WalletType,
    default: false,
    matchAll: [
      {
        field: 'type',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Request',
    key: 'request',
    icon: 'Option-Horizontal',
    // page: 'transaction', // should be in transaction-request
    height: 110,
    component: filters.Request,
    default: false
  },
  {
    title: 'Wallet Types',
    key: 'wallet-types',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 165,
    component: filters.WalletCheckbox,
    default: true,
    matchAny: [
      {
        field: 'status',
        comparator: 'contains'
      }
    ]
  }
]
