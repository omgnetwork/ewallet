import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';

class OMGPager extends Component {
  constructor(props) {
    super(props);
    this.handlePrevious = this.handlePrevious.bind(this);
    this.handleNext = this.handleNext.bind(this);
  }

  handlePrevious() {
    const { page, onPageChange } = this.props;
    onPageChange(page - 1);
  }

  handleNext() {
    const { page, onPageChange } = this.props;
    onPageChange(page + 1);
  }

  render() {
    const {
      isFirstPage, isLastPage, loading, page,
    } = this.props;
    return (
      <div className="omg_pager">
        {!isFirstPage &&
        <Button className="omg_pager__item" disabled={loading} href="#" onClick={this.handlePrevious}>
          &lt;
        </Button>}
        <span className="ml-1 mr-1">
          {page}
        </span>
        {!isLastPage &&
        <Button className="omg_pager__item" disabled={loading} href="#" onClick={this.handleNext}>
          &gt;
        </Button>}
      </div>
    );
  }
}

const mapStateToProps = (state) => {
  const { global } = state;
  return {
    loading: global.loading,
  };
};

OMGPager.propTypes = {
  isFirstPage: PropTypes.bool.isRequired,
  isLastPage: PropTypes.bool.isRequired,
  loading: PropTypes.bool.isRequired,
  onPageChange: PropTypes.func.isRequired,
  page: PropTypes.number.isRequired,
};

export default connect(mapStateToProps, null)(localize(OMGPager, 'locale'));
