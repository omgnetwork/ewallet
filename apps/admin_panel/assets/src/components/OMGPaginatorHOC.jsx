import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import defaultPagination from '../constants/pagination.constants';
import URLActions from '../actions/url.actions';
import OMGPager from '../components/OMGPager';

const OMGPaginatorFactory = (PaginatedComponent, dataLoader) => {
  class OMGPaginatorHOC extends Component {
    constructor(props) {
      super(props);
      this.state = {
        page: defaultPagination.PAGE,
        per: defaultPagination.PER,
        isLastPage: true,
        isFirstPage: true,
        data: [],
        query: '',
        // sort_by: 'id',
        // sort_dir: 'asc',
      };
      this.handlePageChange = this.handlePageChange.bind(this);
      this.updateURL = this.updateURL.bind(this);
      this.onURLChange = this.onURLChange.bind(this);
      this.updateQuery = this.updateQuery.bind(this);
      this.updateSorting = this.updateSorting.bind(this);
    }

    componentDidMount() {
      const { history } = this.props;
      URLActions.processURLParams(history.location, this.onURLChange);
    }

    componentWillReceiveProps(nextProps) {
      const newLocation = nextProps.location;
      const { location } = this.props;
      if (newLocation.search !== location.search) {
        URLActions.processURLParams(newLocation, this.onURLChange);
      }
    }

    onURLChange(params) {
      this.setState(params);
      const { loadData } = this.props;
      loadData(params, (data, pagination) => {
        this.setState({
          data,
          page: pagination.current_page,
          isFirstPage: pagination.is_first_page,
          isLastPage: pagination.is_last_page,
        });
      });
    }

    handlePageChange(newPage) {
      this.setState(
        {
          page: newPage,
        },
        this.updateURL,
      );
    }

    updateURL() {
      const { history } = this.props;
      const { page, per, query } = this.state;
      const params = {
        page,
        per,
        query,
      };
      URLActions.updateURL(history.push, history.location.pathname, params);
    }

    updateQuery(query) {
      this.setState(
        {
          query,
          page: defaultPagination.PAGE,
          isLastPage: true,
          isFirstPage: true,
        },
        this.updateURL,
      );
    }

    updateSorting(sortBy, sortDir) {
      const { data } = this.state;
      console.log(data, sortBy, sortDir);
      // this.setState({
      // sort_by: sortBy,
      // sort_dir: sortDir,
      // });
    }

    render() {
      const {
        isFirstPage, isLastPage, page, data, query,
      } = this.state;

      const {
        history,
      } = this.props;

      return (
        <div>
          <PaginatedComponent
            data={data}
            history={history}
            query={query}
            updateQuery={this.updateQuery}
            updateSorting={this.updateSorting}
          />
          <OMGPager
            isFirstPage={isFirstPage}
            isLastPage={isLastPage}
            onPageChange={this.handlePageChange}
            page={page}
          />
        </div>
      );
    }
  }

  OMGPaginatorHOC.propTypes = {
    history: PropTypes.object.isRequired,
    loadData: PropTypes.func.isRequired,
    location: PropTypes.object.isRequired,
  };

  function mapDispatchToProps(dispatch) {
    return {
      loadData: (query, onSuccess) => dispatch(dataLoader(query, onSuccess)),
    };
  }

  return connect(null, mapDispatchToProps)(OMGPaginatorHOC);
};

export default OMGPaginatorFactory;
