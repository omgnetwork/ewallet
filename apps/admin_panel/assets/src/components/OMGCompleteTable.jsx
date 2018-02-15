import React, { Component } from 'react';
import { localize } from 'react-localize-redux';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import OMGPaginatorFactory from './OMGPaginatorHOC';
import OMGHeader from './OMGHeader';
import OMGTable from './OMGTable';
import { accountURL } from '../helpers/urlFormatter';

class OMGCompleteTable extends Component {
  constructor() {
    super();
    this.onNewClick = this.onNewClick.bind(this);
  }

  onNewClick() {
    const { createRecordUrl, history, session } = this.props;
    history.push(accountURL(session, createRecordUrl));
  }

  render() {
    const {
      data,
      query,
      headerText,
      handleActions,
      updateQuery,
      updateSorting,
      sort,
      translate,
      tables,
      visible,
    } = this.props;
    const { contents, headers } = tables(translate, data, handleActions);
    return (
      <div>
        <OMGHeader
          handleAdd={this.onNewClick}
          handleSearchChange={updateQuery}
          headerText={headerText}
          query={query}
          visible={visible}
        />
        <OMGTable
          content={contents}
          headers={headers}
          sort={sort}
          updateSorting={updateSorting}
        />
      </div>
    );
  }
}

OMGCompleteTable.propTypes = {
  createRecordUrl: PropTypes.string,
  data: PropTypes.arrayOf(PropTypes.object).isRequired,
  handleActions: PropTypes.object,
  headerText: PropTypes.object.isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  session: PropTypes.object.isRequired,
  sort: PropTypes.object.isRequired,
  tables: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
  visible: PropTypes.shape({
    addBtn: PropTypes.bool,
  }),
};

OMGCompleteTable.defaultProps = {
  createRecordUrl: '',
  handleActions: { },
  visible: {
    addBtn: true,
  },
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const { session } = state;
  return {
    loading, session,
  };
}


export default withRouter(connect(mapStateToProps, null)(localize(OMGPaginatorFactory(OMGCompleteTable), 'locale')));
