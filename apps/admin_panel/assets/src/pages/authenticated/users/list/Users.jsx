import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGHeader from '../../../../components/OMGHeader';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';
import OMGTable from '../../../../components/OMGTable';
import dateFormatter from '../../../../helpers/dateFormatter';
import tableConstants from '../../../../constants/table.constants';
import { accountURL } from '../../../../helpers/urlFormatter';

class Users extends Component {
  constructor() {
    super();
    this.onNewUser = this.onNewUser.bind(this);
    this.localizedText = {
      title: 'users.header.users',
      add: 'users.header.new_user',
      advancedFilters: 'users.header.advanced_filters',
      export: 'users.header.export',
    };
  }

  onNewUser() {
    const { history, session } = this.props;
    history.push(accountURL(session, '/users/new'));
  }

  render() {
    const {
      data, query, updateQuery, updateSorting, sort, translate,
    } = this.props;

    const headers = {
      id: { title: translate('users.table.id'), sortable: true },
      provider_user_id: { title: translate('users.table.provider_user_id'), sortable: true },
      username: { title: translate('users.table.username'), sortable: true },
      created_at: { title: translate('users.table.created_at'), sortable: true },
      updated_at: { title: translate('users.table.updated_at'), sortable: true },
    };

    const content = data.map(v => ({
      id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
      username: { type: tableConstants.PROPERTY, value: v.username, shortened: false },
      provider_user_id: {
        type: tableConstants.PROPERTY,
        value: v.provider_user_id,
        shortened: false,
      },
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
    }));

    return (
      <div>
        <OMGHeader
          handleAdd={this.onNewUser}
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

Users.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
    master: false,
    description: PropTypes.string,
    created_at: PropTypes.string.isRequired,
    updated_at: PropTypes.string.isRequired,
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

const dataLoader = (query, callback) => Actions.loadUsers(query, callback);

const WrappedUsers = connect(mapStateToProps)(OMGPaginatorHOC(localize(Users, 'locale'), dataLoader));

export default withRouter(WrappedUsers);
