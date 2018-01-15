import request from './api_service';

export function getAll(params, callback) {
  // const {
  //   per, sort, query, ...rest
  // } = params;
  // return request(
  //   'transactions.all',
  //   JSON.stringify({
  //     per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
  //   }),
  //   callback,
  // );
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
          id: 1,
          amount: 2,
          token: 'ETH',
          balance_from: 'e73d230d-2345-43b1-a99a-25d205a18efc',
          balance_to: 'a946822d-efb6-47fc-8625-a02be1f21297',
          date: new Date('2018-01-11').toLocaleDateString(),
          status: 'pending',
          idempotency_token: 'idempotency_token_1',
        },
        {
          id: 2,
          amount: 100.5,
          token: 'OMG',
          balance_from: 'a946822d-efb6-47fc-8625-a02be1f21297',
          balance_to: 'e73d230d-2345-43b1-a99a-25d205a18efc',
          date: new Date('2018-01-10').toLocaleDateString(),
          status: 'failed',
          idempotency_token: 'idempotency_token_2',
        },
        {
          id: 3,
          amount: 2345.67,
          token: 'XRP',
          balance_from: '479e1fbd-67da-4bc8-897e-a9a790d46191',
          balance_to: '6d274094-e18f-4d74-bae6-e906838352e8',
          date: new Date('2018-01-09').toLocaleDateString(),
          status: 'confirmed',
          idempotency_token: 'idempotency_token_3',
        },
        {
          id: 4,
          amount: 1.12,
          token: 'BTC',
          balance_from: '6d274094-e18f-4d74-bae6-e906838352e8',
          balance_to: '479e1fbd-67da-4bc8-897e-a9a790d46191',
          date: new Date('2018-01-08').toLocaleDateString(),
          status: 'pending',
          idempotency_token: 'idempotency_token_4',
        },
      ],
    },
  };
  callback(null, mock.data);
}

export function create(params, callback) {
  callback(null, { id: 1234 });
  // return request('transactions.create', JSON.stringify(params), callback);
}
