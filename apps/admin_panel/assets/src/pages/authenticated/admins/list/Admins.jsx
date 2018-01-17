import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import AdminsHeader from './AdminsHeader';

class Admins extends Component {
  constructor(props) {
    super(props);
    const { translate } = props;
    this.headers = {
      id: translate('admins.table.id'),
      email: translate('admins.table.email'),
      created_at: translate('admins.table.created_at'),
      updated_at: translate('admins.table.updated_at'),
    };
  }

  render() {
    const {
      data, query, updateQuery, sort, updateSorting,
    } = this.props;

    return (
      <div>
        <AdminsHeader
          handleSearchChange={updateQuery}
          query={query}
        />
        <OMGTable
          contents={data}
          headers={this.headers}
          shortenedColumnIds={['id']}
          sort={sort}
          updateSorting={updateSorting}
        />
      </div>
    );
  }
}

Admins.defaultProps = {};

Admins.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    email: PropTypes.string.isRequired,
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

const dataLoader = (query, callback) => Actions.loadAdmins(query, callback);

const WrappedAdmins = OMGPaginatorFactory(localize(Admins, 'locale'), dataLoader);

export default withRouter(WrappedAdmins);
