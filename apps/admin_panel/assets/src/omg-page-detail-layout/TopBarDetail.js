import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Breadcrumb, Button, Icon } from '../omg-uikit'
const TopBarAction = styled.div`
  flex: 0 1 auto;
  margin-left: auto;
  button {
    
    font-size: 14px;
    :not(:last-child) {
      margin-right: 15px;
    }
  }
  span {
    vertical-align: middle;
  }
`
const TopBarTitle = styled.div`
  flex: 1 1 auto;
`
const TopBar = styled.div`
  display: flex;
`
export default class TopBarDetail extends Component {
  static propTypes = {
    title: PropTypes.string,
    breadcrumbItems: PropTypes.array,
    buttons: PropTypes.array
  }

  render () {
    return (
      <TopBar>
        <TopBarTitle>
          <h1>{this.props.title}</h1>
          <Breadcrumb items={this.props.breadcrumbItems} />
        </TopBarTitle>
        <TopBarAction>
          <Button styleType='ghost' size='small'>
            <Icon name='Export' />Export
          </Button>
          {this.props.buttons}
        </TopBarAction>
      </TopBar>
    )
  }
}
