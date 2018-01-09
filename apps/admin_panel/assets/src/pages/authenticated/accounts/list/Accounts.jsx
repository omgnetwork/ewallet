import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import AccountsHeader from './AccountsHeader';
import AccountsTable from './AccountsTable';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';


class Accounts extends Component {
  constructor(props) {
    super(props);
    this.onNewAccount = this.onNewAccount.bind(this);
  }

  onNewAccount() {
    this.props.history.push('/accounts/new');
  }

  render() {
    const {
      data, query,
    } = this.props;

    return (
      <div>
        <AccountsHeader
          query={query}
          onSearchChange={this.props.updateQuery}
          onNewAccount={this.onNewAccount}
        />
        <AccountsTable accounts={data} />
      </div>
    );
  }
}

Accounts.propTypes = {
  updateQuery: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    master: false,
    description: PropTypes.string,
  })).isRequired,
};

export default withRouter(OMGPaginatorHOC(
  Accounts,
  (query, callback) => Actions.loadAccounts(query, callback),
));
