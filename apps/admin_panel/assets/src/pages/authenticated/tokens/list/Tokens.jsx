import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { localize } from 'react-localize-redux';
import FA from 'react-fontawesome';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import OMGHeader from '../../../../components/OMGHeader';
import dateFormatter from '../../../../helpers/dateFormatter';
import tableConstants from '../../../../constants/table.constants';
import { accountURL } from '../../../../helpers/urlFormatter';

class Tokens extends Component {
  constructor(props) {
    super(props);
    this.onNewToken = this.onNewToken.bind(this);
    this.localizedText = {
      title: 'tokens.header.tokens',
      advancedFilters: 'tokens.header.advanced_filters',
      add: 'tokens.header.new_token',
      export: 'tokens.header.export',
    };
  }

  onNewToken() {
    const { history, session } = this.props;
    history.push(accountURL(session, '/tokens/new'));
  }

  render() {
    const {
      data, query, updateQuery, sort, updateSorting, translate,
    } = this.props;

    const headers = {
      id: { title: translate('tokens.table.id'), sortable: true },
      symbol: { title: translate('tokens.table.symbol'), sortable: true },
      name: { title: translate('tokens.table.name'), sortable: true },
      subunit_to_unit: { title: translate('tokens.table.subunit_to_unit'), sortable: true },
      account: { title: translate('tokens.table.account'), sortable: true },
      created_at: { title: translate('tokens.table.created_at'), sortable: true },
      updated_at: { title: translate('tokens.table.updated_at'), sortable: true },
      locked: { title: translate('tokens.table.locked'), sortable: true },
    };

    const content = data.map(v => ({
      id: { type: tableConstants.PROPERTY, value: v.id, shortened: true },
      symbol: { type: tableConstants.PROPERTY, value: v.symbol, shortened: false },
      name: { type: tableConstants.PROPERTY, value: v.name, shortened: false },
      subunit_to_unit: {
        type: tableConstants.PROPERTY,
        value: v.subunit_to_unit,
        shortened: false,
      },
      account: { type: tableConstants.PROPERTY, value: v.account, shortened: false },
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
      locked: {
        type: tableConstants.PROPERTY,
        value: v.locked ? <FA name="lock" /> : <FA name="unlock" />,
        shortened: false,
      },
    }));

    return (
      <div>
        <OMGHeader
          handleAdd={this.onNewToken}
          handleSearchChange={updateQuery}
          localizedText={this.localizedText}
          query={query}
        />
        <OMGTable
          content={content}
          headers={headers}
          shortenedColumnIds={['account']}
          sort={sort}
          updateSorting={updateSorting}
        />
      </div>
    );
  }
}

Tokens.defaultProps = {};

Tokens.propTypes = {
  data: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    symbol: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    subunitToUnit: PropTypes.number.isRequired,
    locked: PropTypes.bool.isRequired,
    account: PropTypes.string.isRequired,
    createdAt: PropTypes.string.isRequired,
    updatedAt: PropTypes.string.isRequired,
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

const dataLoader = (query, callback) => Actions.loadTokens(query, callback);

const WrappedTokens = connect(mapStateToProps)(OMGPaginatorFactory(localize(Tokens, 'locale'), dataLoader));

export default withRouter(WrappedTokens);
