import dateFormatter from '../../helpers/dateFormatter';

export function getAll() {
  const mock = {
    version: '1',
    success: true,
    data: {
      pagination: {
        per_page: 10,
        is_last_page: true,
        is_first_page: true,
        current_page: 1,
      },
      object: 'list',
      data: [
        {
          id: '1',
          symbol: 'OMG',
          name: 'OmiseGO',
          subunitToUnit: 100000,
          account: '73d230d-2345-43b1-a99a-25d205a18efc',
          createdAt: dateFormatter.format('2018-01-12T11:33:12.000Z'),
          updatedAt: dateFormatter.format('2018-01-13T09:08:23.000Z'),
          locked: true,
        },
        {
          id: '2',
          symbol: 'ETH',
          name: 'Ethereum',
          subunitToUnit: 1000,
          account: '73d230d-2345-43b1-a99a-25d205a18efc',
          createdAt: dateFormatter.format('2018-01-12T14:44:00.000Z'),
          updatedAt: dateFormatter.format('2018-01-13T14:52:50.000Z'),
          locked: false,
        },
        {
          id: '3',
          symbol: 'XRP',
          name: 'Ripple',
          subunitToUnit: 100000,
          account: '73d230d-2345-43b1-a99a-25d205a18efc',
          createdAt: dateFormatter.format('2018-01-12T18:33:55.000Z'),
          updatedAt: dateFormatter.format('2018-01-12T19:22:01.000Z'),
          locked: true,
        },
        {
          id: '4',
          symbol: 'XLM',
          name: 'Stellar',
          subunitToUnit: 1000000000,
          account: '73d230d-2345-43b1-a99a-25d205a18efc',
          createdAt: dateFormatter.format('2018-01-13T01:05:00.000Z'),
          updatedAt: dateFormatter.format('2018-01-14T07:44:00.000Z'),
          locked: false,
        },
      ],
    },
  };
  return new Promise(resolve => resolve(mock.data));
}

export function create(params, callback) {
  callback(null, { id: 1234 });
}
