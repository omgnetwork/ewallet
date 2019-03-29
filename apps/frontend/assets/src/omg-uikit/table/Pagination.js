import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const PaginationContainer = styled.div`
  text-align: center;
  margin: 0 auto;
  width: 100%;
`
const PaginationItem = styled.div`
  display: inline-block;
  color: ${props => props.active ? props.theme.colors.B400 : props.theme.colors.B100};
  padding: 10px;
  cursor: pointer;
`
export default class Pagination extends Component {
  static propTypes = {
    itemCounts: PropTypes.number,
    perPage: PropTypes.number,
    onClickPagination: PropTypes.func,
    activeKey: PropTypes.number
  }
  static defaultProps = {
    perPage: 10
  }

  render () {
    const n = Math.max(Math.ceil(this.props.itemCounts / this.props.perPage), 1)
    return n === 1 ? null : (
      <PaginationContainer {...this.props}>
        {Array(n).fill().map((x, i) => {
          return (
            <PaginationItem active={this.props.activeKey === i + 1} key={i} onClick={this.props.onClickPagination(i + 1)}>{i + 1}</PaginationItem>
          )
        })}
      </PaginationContainer>
    )
  }
}
