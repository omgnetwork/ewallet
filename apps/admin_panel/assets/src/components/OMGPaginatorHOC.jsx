import React, { Component } from 'react';
import PropTypes from 'prop-types';
import defaultPagination from '../constants/pagination.constants';
import URLActions from '../actions/url.actions';
import OMGPager from '../components/OMGPager';

const OMGPaginatorFactory = (PaginatedComponent) => {
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
        sort: {
          by: 'id',
          dir: 'asc',
        },
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
      loadData(params, ({ data, pagination }) => {
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
      const {
        page, per, query, sort,
      } = this.state;
      const params = {
        page,
        per,
        query,
        sort_by: sort.by,
        sort_dir: sort.dir,
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

    updateSorting(sort) {
      this.setState({
        sort,
      }, this.updateURL);
    }

    render() {
      const {
        isFirstPage, isLastPage, page, data, query, sort,
      } = this.state;

      const { history, ...rest } = this.props;

      return (
        <div>
          <PaginatedComponent
            data={data}
            history={history}
            query={query}
            sort={sort}
            updateQuery={this.updateQuery}
            updateSorting={this.updateSorting}
            {...rest}
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

  return OMGPaginatorHOC;
};

export default OMGPaginatorFactory;
