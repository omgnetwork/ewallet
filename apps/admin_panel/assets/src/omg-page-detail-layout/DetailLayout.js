import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
const DetailLayoutContainer = styled.div`
  padding: 20px 0;
  display: flex;
  align-items: flex-start;
  div > i {
    font-size: 24px;
    margin-top: 18px;
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
          <div onClick={this.props.history.goBack}>
            <Icon name='Arrow-Left' />
          </div>
          {this.props.children}
        </DetailLayoutContainer>
      )
    }
  }
)
