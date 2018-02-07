import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import OMGHeader from '../../../../components/OMGHeader';
import dateFormatter from '../../../../helpers/dateFormatter';
import tableConstants from '../../../../constants/table.constants';
import { accountURL } from '../../../../helpers/urlFormatter';

class Transactions extends Component {
  constructor(props) {
    super(props);
    this.onNewTransaction = this.onNewTransaction.bind(this);
    this.localizedText = {
      title: 'transactions.header.transactions',
      advancedFilters: 'transactions.header.advanced_filters',
      export: 'transactions.header.export',
      add: 'transactions.header.new_transaction',
    };
  }

  onNewTransaction() {
    const { history, session } = this.props;
    history.push(accountURL(session, '/transactions/new'));
  }

  render() {
    const {
      data, query, updateQuery, sort, updateSorting, translate,
    } = this.props;

    const headers = {
      id: { title: translate('transactions.table.id'), sortable: true },
      amount: { title: translate('transactions.table.amount'), sortable: false },
      token: { title: translate('transactions.table.token'), sortable: false },
      from: { title: translate('transactions.table.from'), sortable: true },
      to: { title: translate('transactions.table.to'), sortable: true },
      idempotency_token: { title: translate('transactions.table.idempotency_token'), sortable: true },
      status: { title: translate('transactions.table.status'), sortable: true },
      created_at: { title: translate('transactions.table.created_at'), sortable: true },
    };

    const content = data.map(v => ({
      id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
      amount: { type: tableConstants.PROPERTY, value: v.amount, shortened: false },
      token: { type: tableConstants.PROPERTY, value: v.minted_token.id, shortened: true },
      from: { type: tableConstants.PROPERTY, value: v.from, shortened: true },
      to: { type: tableConstants.PROPERTY, value: v.to, shortened: true },
      idempotency_token: {
        type: tableConstants.PROPERTY,
        value: v.idempotency_token,
        shortened: true,
      },
      status: { type: tableConstants.PROPERTY, value: v.status, shortened: false },
      created_at: {
        type: tableConstants.PROPERTY,
        value: dateFormatter.format(v.created_at),
        shortened: false,
      },
    }));

    return (
      <div>
        <OMGHeader
          handleAdd={this.onNewTransaction}
          handleSearchChange={updateQuery}
          localizedText={this.localizedText}
          query={query}
        />
        <OMGTable
          content={content}
          headers={headers}
          sort={sort}
          updateSorting={updateSorting}
        />
      </div>
    );
  }
}

Transactions.defaultProps = {};

Transactions.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    amount: PropTypes.number.isRequired,
    minted_token: PropTypes.object.isRequired,
    from: PropTypes.string.isRequired,
    to: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired,
    status: PropTypes.oneOf(['pending', 'confirmed', 'failed']),
  })).isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  session: PropTypes.object.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return {
    session,
  };
}

const dataLoader = (query, callback) => Actions.loadTransactions(query, callback);

const WrappedTransactions = connect(mapStateToProps)(OMGPaginatorFactory(localize(Transactions, 'locale'), dataLoader));

export default withRouter(WrappedTransactions);
