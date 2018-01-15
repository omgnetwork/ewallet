import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import TransactionsHeader from './TransactionsHeader';

class Transactions extends Component {
  constructor(props) {
    super(props);
    const { translate } = props;
    this.headerTitles = [
      'transactions.table.id',
      'transactions.table.amount',
      'transactions.table.token',
      'transactions.table.balance_from',
      'transactions.table.balance_to',
      'transactions.table.date',
      'transactions.table.status',
      'transactions.table.idempotency_token',
    ].map(translate);

    this.onNewTransaction = this.onNewTransaction.bind(this);
  }

  onNewTransaction() {
    const { history } = this.props;
    history.push('/transactions/new');
  }

  render() {
    const {
      data, query, updateQuery, sort, updateSorting,
    } = this.props;

    return (
      <div>
        <TransactionsHeader
          handleNewTransaction={this.onNewTransaction}
          handleSearchChange={updateQuery}
          query={query}
        />
        <OMGTable
          contents={data}
          headerTitles={this.headerTitles}
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
    id: PropTypes.number.isRequired,
    amount: PropTypes.number.isRequired,
    token: PropTypes.string.isRequired,
    balance_from: PropTypes.string.isRequired,
    balance_to: PropTypes.string.isRequired,
    date: PropTypes.string.isRequired,
    status: PropTypes.oneOf(['pending', 'confirmed', 'failed']),
  })).isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => Actions.loadTransactions(query, callback);

const WrappedTransactions = OMGPaginatorFactory(localize(Transactions, 'locale'), dataLoader);

export default withRouter(WrappedTransactions);
