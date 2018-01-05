import React, { Component } from "react";
import { Pager } from 'react-bootstrap';
import { localize } from 'react-localize-redux';

class OMGPager extends Component {

  constructor(props) {
    super(props);
    this.handlePrevious = this.handlePrevious.bind(this)
    this.handleNext = this.handleNext.bind(this)
  }

  render() {
    const { isFirstPage, isLastPage, page, translate } = this.props
    return(
      <Pager>
        {!isFirstPage && <Pager.Item onSelect={this.handlePrevious} href="#">{translate("pagination.previous")}</Pager.Item>}
        {page}
        {!isLastPage && <Pager.Item onSelect={this.handleNext} href="#">{translate("pagination.next")}</Pager.Item>}
      </Pager>
    );
  }

  handlePrevious() {
    const { page, onPageChange } = this.props
    onPageChange(page - 1)
  }

  handleNext() {
    const { page, onPageChange } = this.props
    onPageChange(page + 1)
  }

}

export default localize(OMGPager, 'locale');
