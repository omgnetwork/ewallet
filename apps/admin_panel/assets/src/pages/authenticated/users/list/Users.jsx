import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import UsersHeader from './UsersHeader';
import Actions from './actions';
import OMGPaginatorHOC from '../../../../components/OMGPaginatorHOC';
import OMGTable from '../../../../components/OMGTable';

class Users extends Component {
  constructor(props) {
    super(props);
    const { translate } = this.props;
    this.onNewUser = this.onNewUser.bind(this);
    this.headerTitles = [
      'users.table.id',
      'users.table.provider_user_id',
      'users.table.username',
      'users.table.metadata',
    ].map(translate);
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
      metadata: v.metadata,
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
          headerTitles={this.headerTitles}
          shortenedColumnIndexes={[0]}
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

const dataLoader = (query, callback) => Actions.loadUsers(query, callback);

const WrappedUsers = OMGPaginatorHOC(localize(Users, 'locale'), dataLoader);

export default withRouter(WrappedUsers);
