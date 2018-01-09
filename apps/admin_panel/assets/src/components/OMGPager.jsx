import React, { Component } from 'react';
import { Pager } from 'react-bootstrap';
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
      isFirstPage, isLastPage, page, translate,
    } = this.props;
    return (
      <Pager>
        {!isFirstPage &&
        <Pager.Item href="#" onSelect={this.handlePrevious}>
          {translate('pagination.previous')}
        </Pager.Item>}
        {page}
        {!isLastPage &&
        <Pager.Item href="#" onSelect={this.handleNext}>
          {translate('pagination.next')}
        </Pager.Item>}
      </Pager>
    );
  }
}

OMGPager.propTypes = {
  isFirstPage: PropTypes.bool.isRequired,
  isLastPage: PropTypes.bool.isRequired,
  onPageChange: PropTypes.func.isRequired,
  page: PropTypes.number.isRequired,
  translate: PropTypes.func.isRequired,
};

export default localize(OMGPager, 'locale');
