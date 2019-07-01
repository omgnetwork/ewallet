import filters from './filters'

export const FILTER_MAP = [
  // TRANSACTIONS PAGE --------------
  {
    title: 'Transfer From',
    key: 'transaction-transfer-from',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.SelectWallet,
    default: false,
    matchAll: [
      {
        field: 'from_wallet.address',
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
    component: filters.SelectWallet,
    default: false,
    matchAll: [
      {
        field: 'from_wallet.address',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Target',
    key: 'transaction-target',
    icon: 'Option-Horizontal',
    page: 'transaction',
    height: 110,
    component: filters.SelectWallet,
    default: false,
    matchAny: [
      {
        field: 'to_wallet.address',
        comparator: 'contains'
      },
      {
        field: 'from_wallet.address',
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
  // WALLETS PAGE --------------
  {
    title: 'Wallet Types',
    key: 'wallets-wallet-types',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 166,
    default: true,
    component: filters.Checkbox,
    options: [
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
    title: 'Creation Date',
    key: 'wallets-creation-date',
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
    title: 'Account',
    key: 'wallets-account',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 110,
    component: filters.SelectAccount,
    default: false,
    matchAll: [
      {
        field: 'account.name',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'User',
    key: 'wallets-user',
    icon: 'Option-Horizontal',
    page: 'wallets',
    height: 110,
    component: filters.SelectUser,
    default: false,
    matchAny: [
      {
        field: 'user.username',
        comparator: 'contains'
      },
      {
        field: 'user.email',
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
        label: 'Receive',
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
    title: 'Requires Confirmation',
    key: 'transaction-requests-require-confirmation',
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
    title: 'Creation Date',
    key: 'transaction-requests-creation-date',
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
    title: 'Wallet',
    key: 'transaction-requests-wallet',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 110,
    component: filters.SelectWallet,
    default: false,
    matchAll: [
      {
        field: 'wallet.address',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Select Token',
    key: 'transaction-requests-token',
    icon: 'Option-Horizontal',
    page: 'transaction-requests',
    height: 110,
    component: filters.SelectToken,
    default: false,
    matchAll: [
      {
        field: 'token.symbol',
        comparator: 'contains'
      }
    ]
  },
  // TRANSACTION CONSUMPTIONS PAGE --------------
  {
    title: 'Consumption Date',
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
        label: 'Receive',
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
    title: 'Transaction Request',
    key: 'transaction-consumptions-transaction-request',
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
    title: 'Consumption Wallet',
    key: 'transaction-consumptions-consumer',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.SelectWallet,
    default: false,
    matchAll: [
      {
        field: 'wallet.address',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Request Wallet',
    key: 'transaction-consumptions-request-wallet',
    icon: 'Option-Horizontal',
    page: 'transaction-consumptions',
    height: 110,
    component: filters.SelectWallet,
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
        value: 'auth_token'
      },
      {
        label: 'Wallet',
        value: 'wallet'
      },
      {
        label: 'Request',
        value: 'transaction_request'
      },
      {
        label: 'Consumption',
        value: 'transaction_consumption'
      },
      {
        label: 'Users',
        value: 'user'
      },
      {
        label: 'Keys',
        value: 'key'
      }
    ],
    matchAny: [
      {
        field: 'target_type',
        comparator: 'contains'
      }
    ]
  },
  {
    title: 'Actions',
    key: 'activitylogs-action',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 166,
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
    title: 'Target',
    key: 'activitylogs-target',
    icon: 'Option-Horizontal',
    page: 'activitylogs',
    height: 110,
    component: filters.InputFilter,
    default: false,
    matchAll: [
      {
        field: 'target_identifier',
        comparator: 'contains'
      }
    ]
  }
]
