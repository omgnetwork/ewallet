import React from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import loadAdmins from './actions';
import OMGHeader from '../../../../components/OMGHeader';
import tableConstants from '../../../../constants/table.constants';
import dateFormatter from '../../../../helpers/dateFormatter';

const Admins = ({
  data, query, updateQuery, sort, updateSorting, translate,
}) => {
  const content = data.map(v => ({
    id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
    email: { type: tableConstants.PROPERTY, value: v.email, shortened: false },
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
  const headers = {
    id: { title: translate('admins.table.id'), sortable: true },
    email: { title: translate('admins.table.email'), sortable: true },
    created_at: { title: translate('admins.table.created_at'), sortable: true },
    updated_at: { title: translate('admins.table.updated_at'), sortable: true },
  };

  const localizedText = {
    title: 'admins.header.admins',
    advancedFilters: 'admins.header.advanced_filters',
    export: 'admins.header.export',
  };

  return (
    <div>
      <OMGHeader
        handleSearchChange={updateQuery}
        localizedText={localizedText}
        query={query}
        visible={{ addBtn: false }}
      />
      <OMGTable
        content={content}
        headers={headers}
        sort={sort}
        updateSorting={updateSorting}
      />
    </div>
  );
};


Admins.defaultProps = {};

Admins.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    email: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired,
    updated_at: PropTypes.string.isRequired,
  })).isRequired,
  query: PropTypes.string.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => loadAdmins(query, callback);

const WrappedAdmins = OMGPaginatorFactory(localize(Admins, 'locale'), dataLoader);

export default withRouter(WrappedAdmins);
