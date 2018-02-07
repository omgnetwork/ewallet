import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';
import OMGTable from '../../../../components/OMGTable';
import OMGHeader from '../../../../components/OMGHeader';
import dateFormatter from '../../../../helpers/dateFormatter';
import tableConstants from '../../../../constants/table.constants';
import { accountURL } from '../../../../helpers/urlFormatter';

class Accounts extends Component {
  constructor(props) {
    super(props);
    this.onNewAccount = this.onNewAccount.bind(this);
    this.localizedText = {
      title: 'accounts.header.accounts',
      advancedFilters: 'accounts.header.advanced_filters',
      export: 'accounts.header.export',
      add: 'accounts.header.new_account',
    };
  }

  onNewAccount() {
    const { history, session } = this.props;
    history.push(accountURL(session, '/accounts/new'));
  }

  render() {
    const {
      data, query, updateQuery, updateSorting, sort, translate, handleViewAs,
    } = this.props;

    const headers = {
      id: { title: translate('users.table.id'), sortable: true },
      name: { title: translate('accounts.table.name'), sortable: true },
      master: { title: translate('accounts.table.master'), sortable: true },
      description: { title: translate('accounts.table.description'), sortable: true },
      created_at: { title: translate('accounts.table.created_at'), sortable: true },
      updated_at: { title: translate('accounts.table.updated_at'), sortable: true },
      actions: { title: translate('accounts.table.actions'), sortable: false },
    };

    const content = data.map(v => ({
      id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
      name: { type: tableConstants.PROPERTY, value: v.name, shortened: false },
      master: { type: tableConstants.PROPERTY, value: v.master, shortened: false },
      description: { type: tableConstants.PROPERTY, value: v.description, shortened: false },
      created_at: {
        type: tableConstants.PROPERTY,
        value: dateFormatter.format(v.created_at),
        shortened: false,
      },
      updated_at: {
        type: tableConstants.PROPERTY,
        value: dateFormatter.format(v.updated_at),
        shortened: false,
      },
      action: {
        type: tableConstants.ACTIONS,
        value: [{
          title: translate('accounts.table.view_as'),
          callback: handleViewAs,
        }],
        shortened: false,
      },
    }));

    return (
      <div>
        <OMGHeader
          handleAdd={this.onNewAccount}
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

Accounts.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    master: false,
    description: PropTypes.string,
    created_at: PropTypes.string,
    updated_at: PropTypes.string,
  })).isRequired,
  handleViewAs: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  session: PropTypes.object.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => Actions.loadAccounts(query, callback);
function mapDispatchToProps(dispatch) {
  return {
    handleViewAs: accountId => dispatch(Actions.viewAs(accountId)),
  };
}

function mapStateToProps(state) {
  const { loading } = state.global;
  const { session } = state;
  return {
    loading, session,
  };
}

const WrappedAccounts = connect(mapStateToProps, mapDispatchToProps)(OMGPaginatorHOC(localize(Accounts, 'locale'), dataLoader));

export default withRouter(WrappedAccounts);
