import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon } from '../omg-uikit'
import {Link} from 'react-router-dom'
const DetailLayoutContainer = styled.div`
  padding: 20px 0;
  display: flex;
  align-items: flex-start;
  a > i {
    font-size: 24px;
    margin-top: 18px;
    margin-right: 20px;
    cursor: pointer;
  }
`
export default class DetailLayout extends Component {
  static propTypes = {
    children: PropTypes.node,
    backPath: PropTypes.string.isRequired
  }

  render () {
    return (
      <DetailLayoutContainer>
        <Link to={this.props.backPath}><Icon name='Arrow-Left' /></Link>
        {this.props.children}
      </DetailLayoutContainer>
    )
  }
}
