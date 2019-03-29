import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Icon from '../icon'
const BreadcrumbContainer = styled.div`
  position: relative;
  color: ${props => props.theme.colors.B100};
  i {
    padding: 0 5px;
    font-size: inherit;
  }
  a {
    color: inherit;
  }
`
export default class Breadcrumb extends Component {
  static propTypes = {
    items: PropTypes.array.isRequired
  }

  render () {
    const items = this.props.items.filter(x => x)
    return (
      <BreadcrumbContainer>
        {items.reduce((prev, curr, index) => {
          prev.push(<span key={index}>{curr}</span>)
          if (index < items.length - 1) prev.push(<Icon name='Chevron-Right' key={`${index}-chevron`} />)
          return prev
        }, [])}
      </BreadcrumbContainer>
    )
  }
}
