import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import AccountsHeader from './AccountsHeader';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';
import OMGTable from '../../../../components/OMGTable';

class Accounts extends Component {
  constructor(props) {
    super(props);
    const { translate } = this.props;
    this.onNewAccount = this.onNewAccount.bind(this);
    this.headers = {
      id: translate('users.table.id'),
      name: translate('accounts.table.name'),
      master: translate('accounts.table.master'),
      description: translate('accounts.table.description'),
    };
  }

  onNewAccount() {
    const { history } = this.props;
    history.push('/accounts/new');
  }

  render() {
    const {
      data, query, updateQuery, updateSorting, sort,
    } = this.props;

    const contents = data.map(v => ({
      id: v.id,
      name: v.name,
      master: v.master,
      description: v.description,
    }));

    return (
      <div>
        <AccountsHeader
          handleNewAccount={this.onNewAccount}
          handleSearchChange={updateQuery}
          query={query}
        />
        <OMGTable
          contents={contents}
          headers={this.headers}
          shortenedColumnIds={['id']}
          sort={sort}
          updateSorting={updateSorting}
        />
      </div>
    );
  }
}

Accounts.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    master: false,
    description: PropTypes.string,
  })).isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => Actions.loadAccounts(query, callback);

const WrappedAccounts = OMGPaginatorHOC(localize(Accounts, 'locale'), dataLoader);

export default withRouter(WrappedAccounts);
