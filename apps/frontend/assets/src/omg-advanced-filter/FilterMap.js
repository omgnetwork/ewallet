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
    component: filters.SelectAccount,
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
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
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
    height: 267,
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
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
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
    component: filters.MultiSelectAccounts,
    default: false,
    matchAny: [
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
    component: filters.MultiSelectUsers,
    default: false,
    matchAny: [
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
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
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
    component: filters.MultiSelectAccounts,
    default: false,
    matchAny: [
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
    component: filters.MultiSelectWallets,
    default: false,
    matchAny: [
      {
        field: 'wallet.address',
        comparator: 'contains'
      }
    ]
  },
  // TRANSACTION CONSUMPTIONS PAGE --------------
  {
    title: 'Consumed Date',
    key: 'transaction-consumptions-consumed-date',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 205,
    component: filters.DateTime,
    default: true,
    matchAll: [
      {
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
        comparator: 'lte',
        value: '{{ endDate }}'
      }
    ]
  },
  {
    title: 'Consumption Type',
    key: 'transaction-consumptions-consumption-type',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
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
        field: 'transaction_request.type',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Status',
    key: 'transaction-consumptions-status',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 166,
    default: true,
    component: filters.Checkbox,
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
    title: 'Specify Transaction Request',
    key: 'transaction-consumptions-specify-transaction-request',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'transaction_request.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Accounts',
    key: 'transaction-consumptions-specify-accounts',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.MultiSelectAccounts,
    default: false,
    matchAny: [
      {
        field: 'account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Consumer',
    key: 'transaction-consumptions-specify-consumer',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.MultiSelectUsers,
    default: false,
    matchAny: [
      {
        field: 'user.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Requested Wallet',
    key: 'transaction-consumptions-specify-requested-wallet',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.MultiSelectWallets,
    default: false,
    matchAll: [
      {
        field: 'wallet.address',
        comparator: 'contains'
      }
    ]
  },
  // USERS PAGE --------------
  {
    title: 'Join Date',
    key: 'users-join-date',
    icon: 'Option-Horizontal',
    page: 'users',
    height: 205,
    component: filters.DateTime,
    default: true,
    matchAll: [
      {
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
        comparator: 'lte',
        value: '{{ endDate }}'
      }
    ]
  },
  {
    title: 'Specify Accounts',
    key: 'users-specify-accounts',
    icon: 'Option-Horizontal',
    page: 'users',
    height: 110,
    component: filters.MultiSelectAccounts,
    default: true,
    matchAny: [
      {
        field: 'accounts.id',
        comparator: 'contains'
      }
    ]
  },
  // ACTIVITY LOG PAGE --------------
  {
    title: 'Date & Time',
    key: 'activitylogs-date',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 205,
    component: filters.DateTime,
    default: true,
    matchAll: [
      {
        field: 'created_at',
        comparator: 'gte',
        value: '{{ startDate }}'
      },
      {
        field: 'created_at',
        comparator: 'lte',
        value: '{{ endDate }}'
      }
    ]
  },
  {
    title: 'Section',
    key: 'activitylogs-section',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 285,
    component: filters.Checkbox,
    default: true,
    options: [
      {
        label: 'Account',
        value: 'account'
      },
      {
        label: 'Token',
        value: 'token'
      },
      {
        label: 'Wallet',
        value: 'wallet'
      },
      {
        label: 'Request',
        value: 'request'
      },
      {
        label: 'Consumption',
        value: 'consumption'
      },
      {
        label: 'Users',
        value: 'users'
      },
      {
        label: 'Keys',
        value: 'keys'
      }
    ],
    matchAny: [
      {
        field: 'section',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Actions',
    key: 'activitylogs-action',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 196,
    component: filters.Checkbox,
    default: false,
    options: [
      {
        label: 'Insert',
        value: 'insert'
      },
      {
        label: 'Update',
        value: 'update'
      },
      {
        label: 'Edit',
        value: 'edit'
      },
      {
        label: 'Delete',
        value: 'delete'
      }
    ],
    matchAny: [
      {
        field: 'action',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Target',
    key: 'activitylogs-specify-target',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'target',
        comparator: 'contains'
      }
    ]
  },
  // TOKEN PAGE --------------
  {
    title: 'Wallet Types',
    key: 'tokens-wallet-types',
    icon: 'Option-Horizontal',
    page: 'tokens',
    height: 267,
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
        field: 'account.wallets.identifier',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Accounts',
    key: 'tokens-specify-accounts',
    icon: 'Option-Horizontal',
    page: 'tokens',
    height: 110,
    component: filters.MultiSelectAccounts,
    default: false,
    matchAny: [
      {
        field: 'account.id',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Specify Wallets',
    placeholder: 'Select Wallet Addresses',
    key: 'tokens-specify-wallets',
    icon: 'Option-Horizontal',
    page: 'tokens',
    height: 110,
    component: filters.MultiSelectWallets,
    default: true,
    matchAny: [
      {
        field: 'account.wallets.address',
        comparator: 'contains'
      }
    ]
  }
]
