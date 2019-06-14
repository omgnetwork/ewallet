import filters from './filters'

export const FILTER_MAP = [
  // TRANSACTIONS PAGE --------------
  {
    title: 'Transfer From',
    key: 'transfer-from',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.SelectAccount,
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
    component: filters.SelectAccount,
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
    component: filters.InputFilter,
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
    height: 166,
    component: filters.Checkbox,
    default: true,
    options: [
      {
        label: 'Confirmed',
        value: 'confirmed'
      },
      {
        label: 'Pending',
        value: 'pending'
      },
      {
        label: 'Failed',
        value: 'failed'
      }
    ],
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
    component: filters.SelectFilter,
    default: false,
    options: [
      {
        key: 'internal',
        value: 'Internal'
      },
      {
        key: 'external',
        value: 'External'
      }
    ],
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
    component: filters.InputFilter,
    default: false
  },
  // WALLETS PAGE --------------
  {
    title: 'Wallet Types',
    key: 'wallet-types',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 287,
    default: true,
    component: filters.Checkbox,
    options: [
      {
        label: 'Local Wallet',
        value: 'local'
      },
      {
        label: 'Cold Wallet',
        value: 'cold'
      },
      {
        label: 'Hot Wallet',
        value: 'hot'
      },
      'divider',
      {
        label: 'Primary Wallet',
        value: 'primary'
      },
      {
        label: 'Secondary Wallet',
        value: 'secondary'
      },
      {
        label: 'Burn Wallet',
        value: 'burn'
      }
    ],
    matchAny: [
      {
        field: 'identifier',
        comparator: 'contains'
      }
    ]
  }
]
