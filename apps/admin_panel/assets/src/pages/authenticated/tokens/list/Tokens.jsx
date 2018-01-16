import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import FA from 'react-fontawesome';
import PropTypes from 'prop-types';
import OMGTable from '../../../../components/OMGTable';
import OMGPaginatorFactory from '../../../../components/OMGPaginatorHOC';
import Actions from './actions';
import TokensHeader from './TokensHeader';

class Tokens extends Component {
  constructor(props) {
    super(props);
    const { translate } = props;
    this.headerTitles = [
      'tokens.table.id',
      'tokens.table.symbol',
      'tokens.table.name',
      'tokens.table.subunit_to_unit',
      'tokens.table.account',
      'tokens.table.created_at',
      'tokens.table.updated_at',
      'tokens.table.locked',
    ].map(translate);

    this.onNewToken = this.onNewToken.bind(this);
  }

  onNewToken() {
    const { history } = this.props;
    history.push('/tokens/new');
  }

  render() {
    const {
      data, query, updateQuery, sort, updateSorting,
    } = this.props;

    const newData = data.map(v => ({
      ...v,
      locked: v.locked ? <FA name="lock" /> : <FA name="unlock" />,
    }));

    return (
      <div>
        <TokensHeader
          handleNewToken={this.onNewToken}
          handleSearchChange={updateQuery}
          query={query}
        />
        <OMGTable
          contents={newData}
          headerTitles={this.headerTitles}
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
    id: PropTypes.number.isRequired,
    symbol: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    subunitToUnit: PropTypes.string.isRequired,
    locked: PropTypes.bool.isRequired,
    account: PropTypes.string.isRequired,
    createdAt: PropTypes.string.isRequired,
    updatedAt: PropTypes.string.isRequired,
  })).isRequired,
  history: PropTypes.object.isRequired,
  query: PropTypes.string.isRequired,
  sort: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
  updateQuery: PropTypes.func.isRequired,
  updateSorting: PropTypes.func.isRequired,
};

const dataLoader = (query, callback) => Actions.loadTokens(query, callback);

const WrappedTokens = OMGPaginatorFactory(localize(Tokens, 'locale'), dataLoader);

export default withRouter(WrappedTokens);
