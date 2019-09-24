import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link, withRouter } from 'react-router-dom'

import { Tag } from '../omg-uikit'

const KeyTopBar = styled.div`
  p {
    color: ${props => props.theme.colors.B100};
    max-width: 80%;
  }
  > div:first-child {
    display: flex;
    align-items: center;
  }
  button:last-child {
    margin-left: auto;
  }
  a {
    margin-right: 10px;
  }
`

const TabMenu = ({ location }) => {
  const activeTab = location.pathname.split('/')[3]

  return (
    <KeyTopBar>
      <Link to='tokens'>
        <Tag
          title='Tokens'
          icon='Token'
          active={activeTab === 'tokens'}
          hoverStyle
        />
      </Link>
      <Link to='blockchain_transactions'>
        <Tag
          title='Transactions'
          icon='Transaction'
          active={activeTab === 'blockchain_transactions'}
          hoverStyle
        />
      </Link>
    </KeyTopBar>
  )
}

TabMenu.propTypes = {
  location: PropTypes.object
}

export default withRouter(TabMenu)
