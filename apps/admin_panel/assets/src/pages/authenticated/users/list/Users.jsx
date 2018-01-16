import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import UsersHeader from './UsersHeader';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';
import OMGTable from '../../../../components/OMGTable';
import dateFormatter from '../../../../helpers/dateFormatter';

class Users extends Component {
  constructor(props) {
    super(props);
    const { translate } = this.props;
    this.onNewUser = this.onNewUser.bind(this);
    this.headers = {
      id: translate('users.table.id'),
      provider_user_id: translate('users.table.provider_user_id'),
      username: translate('users.table.username'),
      created_at: translate('users.table.created_at'),
      updated_at: translate('users.table.updated_at'),
    };
  }

  onNewUser() {
    const { history } = this.props;
    history.push('/users/new');
  }

  render() {
    const {
      data, query, updateQuery, updateSorting, sort,
    } = this.props;

    const contents = data.map(v => ({
      id: v.id,
      provider_user_id: v.provider_user_id,
      username: v.username,
      created_at: dateFormatter.format(v.created_at),
      updated_at: dateFormatter.format(v.updated_at),
    }));

    return (
      <div>
        <UsersHeader
          handleNewUser={this.onNewUser}
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
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => Actions.loadUsers(query, callback);

const WrappedUsers = OMGPaginatorHOC(localize(Users, 'locale'), dataLoader);

export default withRouter(WrappedUsers);
