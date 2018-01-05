import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { PAGINATION } from '../helpers/constants';
import { urlActions } from '../actions';
import OMGPager from '../components/OMGPager';

const OMGPaginatorFactory = (PaginatedComponent, dataLoader) => {
  class OMGPaginatorHOC extends Component {
    constructor(props) {
      super(props);
      this.state = {
        page: PAGINATION.PAGE,
        per: PAGINATION.PER,
        isLastPage: true,
        isFirstPage: true,
        data: [],
        query: '',
      };
      this.onPageChange = this.onPageChange.bind(this);
      this.updateURL = this.updateURL.bind(this);
      this.onURLChange = this.onURLChange.bind(this);
      this.updateQuery = this.updateQuery.bind(this);
    }

    componentDidMount() {
      urlActions.processURLParams(this.props.history.location, this.onURLChange);
    }

    componentWillReceiveProps(nextProps) {
      const newLocation = nextProps.location;
      const oldLocationSearch = this.props.location.search;
      if (newLocation.search !== oldLocationSearch) {
        urlActions.processURLParams(newLocation, this.onURLChange);
      }
    }

    onPageChange(newPage) {
      this.setState(
        {
          page: newPage,
        },
        this.updateURL,
      );
    }

    onURLChange(params) {
      this.setState(params);
      this.props.loadData(params, (data, pagination) => {
        this.setState({
          data,
          page: pagination.current_page,
          isFirstPage: pagination.is_first_page,
          isLastPage: pagination.is_last_page,
        });
      });
    }

    updateURL() {
      const { push, location } = this.props.history;
      const { page, per, query } = this.state;
      const params = {
        page,
        per,
        query,
      };
      urlActions.updateURL(push, location.pathname, params);
    }

    updateQuery(query) {
      this.setState(
        {
          query,
          page: PAGINATION.PAGE,
          isLastPage: true,
          isFirstPage: true,
        },
        this.updateURL,
      );
    }

    render() {
      const {
        isFirstPage, isLastPage, page,
      } = this.state;

      return (
        <div>
          <PaginatedComponent
            history={this.props.history}
            updateQuery={this.updateQuery}
            data={this.state.data}
            query={this.state.query}
          />
          <OMGPager
            isFirstPage={isFirstPage}
            isLastPage={isLastPage}
            page={page}
            onPageChange={this.onPageChange}
          />
        </div>
      );
    }
  }

  OMGPaginatorHOC.propTypes = {
    loadData: PropTypes.func.isRequired,
    history: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
    location: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  };

  function mapDispatchToProps(dispatch) {
    return {
      loadData: (query, onSuccess) => dispatch(dataLoader(query, onSuccess)),
    };
  }

  return connect(null, mapDispatchToProps)(OMGPaginatorHOC);
};

export default OMGPaginatorFactory;
