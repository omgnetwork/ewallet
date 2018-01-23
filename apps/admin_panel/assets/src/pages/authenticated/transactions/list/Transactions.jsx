import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import TransactionsHeader from './TransactionsHeader';
import dateFormatter from '../../../../helpers/dateFormatter';
import tableConstants from '../../../../constants/table.constants';
import { accountURL } from '../../../../helpers/urlFormatter';

class Transactions extends Component {
  constructor(props) {
    super(props);
    this.onNewTransaction = this.onNewTransaction.bind(this);
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
      amount: { title: translate('transactions.table.amount'), sortable: true },
      token: { title: translate('transactions.table.token'), sortable: true },
      balance_from: { title: translate('transactions.table.balance_from'), sortable: true },
      balance_to: { title: translate('transactions.table.balance_to'), sortable: true },
      date: { title: translate('transactions.table.date'), sortable: true },
      status: { title: translate('transactions.table.status'), sortable: true },
      idempotency_token: { title: translate('transactions.table.idempotency_token'), sortable: true },
    };

    const content = data.map(v => ({
      id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
      amount: { type: tableConstants.PROPERTY, value: v.amount, shortened: false },
      token: { type: tableConstants.PROPERTY, value: v.token, shortened: false },
      balance_from: { type: tableConstants.PROPERTY, value: v.balance_from, shortened: true },
      balance_to: { type: tableConstants.PROPERTY, value: v.balance_to, shortened: true },
      date: {
        type: tableConstants.PROPERTY,
        value: dateFormatter.format(v.date),
        shortened: false,
      },
      status: { type: tableConstants.PROPERTY, value: v.status, shortened: false },
      idempotency_token: {
        type: tableConstants.PROPERTY,
        value: v.idempotency_token,
        shortened: false,
      },
    }));

    return (
      <div>
        <TransactionsHeader
          handleNewTransaction={this.onNewTransaction}
          handleSearchChange={updateQuery}
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
