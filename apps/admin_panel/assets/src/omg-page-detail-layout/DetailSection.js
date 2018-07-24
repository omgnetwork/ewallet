import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const DetailContainer = styled.div`
  flex: 1 1 auto;
  margin-bottom: 50px;
  :first-child {
    margin-right: 20px;
  }
  h4 {
    border-bottom: 1px solid ${props => props.theme.colors.S300};
    padding-bottom: 15px;
    margin-bottom: 20px;
  }
  tr {
    border: none !important;
  }
  td,
  th {
    padding: 5px 0 5px 0 !important;
    cursor: auto !important;
  }
  th > * {
    border: none !important;
    padding: 0 !important;
  }
`
export const DetailGroup = styled.div`
  margin-top: 15px;
  color: ${props => props.theme.colors.B200};
  b {
    color: ${props => props.theme.colors.B400};
    width: 200px;
    display: inline-block;
  }
  h5 {
    font-weight: 400;
    color: ${props => props.theme.colors.B100};
    margin-bottom: 2px;
  }
  span {
    vertical-align: bottom;
  }
`

export default class DetailContent extends Component {
  static propTypes = {
    title: PropTypes.string,
    children: PropTypes.node
  }

  render () {
    return (
      <DetailContainer>
        <h4>{this.props.title}</h4>
        {this.props.children}
      </DetailContainer>
    )
  }
}
