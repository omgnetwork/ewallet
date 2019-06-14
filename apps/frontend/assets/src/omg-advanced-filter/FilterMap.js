import filters from './filters'

export const FILTER_MAP = [
  // TRANSACTIONS PAGE --------------
  {
    title: 'Transfer From',
    key: 'transaction-transfer-from',
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
    key: 'transaction-transfer-to',
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
    key: 'transaction-specify-target',
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
    key: 'transaction-date-time',
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
    key: 'transaction-status',
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
    key: 'transaction-wallet-type',
    icon: 'Option-Horizontal',
    // page: 'transaction',
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
    key: 'transaction-request',
    icon: 'Option-Horizontal',
    // page: 'transaction',
    height: 110,
    component: filters.InputFilter,
    default: false
  },
  // WALLETS PAGE --------------
  {
    title: 'Wallet Types',
    key: 'wallets-wallet-types',
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
  },
  {
    title: 'Create Date',
    key: 'wallets-create-date',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 205,
    component: filters.DateTime,
    default: false,
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
    title: 'Specify Accounts',
    key: 'wallets-specify-accounts',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Users',
    key: 'wallets-specify-users',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'user.id',
        comparator: 'contains'
      }
    ]
  },
  // TRANSACTION REQUESTS PAGE --------------
  {
    title: 'Request Type',
    key: 'transaction-requests-request-type',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 136,
    component: filters.RadioCheckbox,
    default: true,
    options: [
      {
        label: 'Send',
        value: 'send'
      },
      {
        label: 'Received',
        value: 'receive'
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
    title: 'Confirmation Type',
    key: 'transaction-requests-confirmation-type',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 136,
    component: filters.RadioCheckbox,
    default: true,
    options: [
      {
        label: 'Yes',
        value: true
      },
      {
        label: 'No',
        value: false
      }
    ],
    matchAll: [
      {
        field: 'require_confirmation',
        comparator: 'eq'
      }
    ]
  },
  {
    title: 'Status',
    key: 'transaction-requests-status',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 136,
    component: filters.RadioCheckbox,
    default: true,
    options: [
      {
        label: 'Valid',
        value: 'valid'
      },
      {
        label: 'Expired',
        value: 'expired'
      }
    ],
    matchAll: [
      {
        field: 'status',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Create Date',
    key: 'transaction-requests-create-date',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 205,
    component: filters.DateTime,
    default: false,
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
    title: 'Specify Accounts',
    key: 'transaction-requests-specify-accounts',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Requested Wallet',
    key: 'transaction-requests-specify-requested-wallet',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'wallet.address',
        comparator: 'contains'
      }
    ]
  }
]
