import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
const DetailLayoutContainer = styled.div`
  padding: 19px 0;
  display: flex;
  align-items: flex-start;
`
const Back = styled.div`
  font-size: 24px;
  margin-top: 18px;
  margin-right: 20px;
  cursor: pointer;
  i {
    font-size: 24px;
    margin-right: 20px;
    cursor: pointer;
  }
`
export default withRouter(
  class DetailLayout extends Component {
    static propTypes = {
      children: PropTypes.node,
      backPath: PropTypes.string.isRequired,
      history: PropTypes.object
    }

    render () {
      return (
        <DetailLayoutContainer>
          <Back onClick={this.props.history.goBack}>
            <Icon name='Arrow-Left' />
          </Back>
          {this.props.children}
        </DetailLayoutContainer>
      )
    }
  }
)
