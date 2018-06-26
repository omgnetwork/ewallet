import React, { PureComponent } from 'react'

import styled from 'styled-components'
import { Icon, Input } from '../omg-uikit'
import { Link, withRouter } from 'react-router-dom'
import clickOutside from '../enhancer/clickOutside'
import PropTypes from 'prop-types'
import queryString from 'query-string'
const TopNavigationContainer = styled.div`
  padding: 20px 0;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  h2 {
    display: inline-block;
    margin-right: 25px;
  }
  > {
    vertical-align: middle;
  }
`
const LeftNavigationContainer = styled.div`
  flex: 1 1 auto;
`
const RightNavigationContainer = styled.div`
  white-space: nowrap;
  button {
    font-size: 14px;
    i {
      margin-right: 10px;
    }
    span {
      vertical-align: middle;
    }
  }
  button:not(:first-child) {
    margin-left: 10px;
  }
`
const TableType = styled.span`
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const Spliiter = styled.span`
  color: ${props => props.theme.colors.S400};
  margin: 0 ${props => (props.gap ? props.gap : '0')}px;
`
const SecondaryActionsContainer = styled.div`
  display: inline-block;
`

export default class TopNavigation extends PureComponent {
  static propTypes = {
    buttons: PropTypes.array,
    title: PropTypes.string,
    types: PropTypes.bool,
    secondaryAction: PropTypes.bool
  }
  static defaultProps = {
    types: true,
    secondaryAction: true
  }
  constructor (props) {
    super(props)
    this.types = ['History', 'Table Info']
  }
  renderTableTypes () {
    return (
      <SecondaryActionsContainer>
        {this.types.reduce((prev, curr, index) => {
          prev.push(
            <Link to='/' key={curr}>
              <TableType>{curr}</TableType>
            </Link>
          )
          if (index !== this.types.length - 1) {
            prev.push(
              <Spliiter key={`${curr}${index}`} gap={10}>
                |
              </Spliiter>
            )
          }
          return prev
        }, [])}
      </SecondaryActionsContainer>
    )
  }
  renderSecondaryActions () {
    return (
      <SecondaryActionsContainer>
        <SearchGroup />
        {/* <Spliiter>|</Spliiter>
        <Icon name='Filter' button /> */}
      </SecondaryActionsContainer>
    )
  }
  render () {
    return (
      <TopNavigationContainer>
        <LeftNavigationContainer>
          <h2>{this.props.title}</h2>
          {/* {this.props.types && this.renderTableTypes()} */}
        </LeftNavigationContainer>
        <RightNavigationContainer>
          {this.props.secondaryAction && this.renderSecondaryActions()}
          {this.props.buttons}
        </RightNavigationContainer>
      </TopNavigationContainer>
    )
  }
}

const SearchGroupContainer = styled.form`
  display: inline-block;
  vertical-align: middle;
  i {
    vertical-align: baseline;
    display: inline-block;
  }
  i[name="Search"] {
    transform: ${props => (props.search ? 'translate3d(0,0,0)' : 'translate3d(150px,0,0)')};
    transition: transform 0.2s;
  }
`
const InlineInput = styled(Input)`
  display: inline-block;
  width: 150px;
  transform: ${props => (props.search ? 'scale3d(1,1,1)' : 'scale3d(0,1,1)')};
  overflow: hidden;
  transition: transform 0.2s;
`
const CloseIconInputContainer = styled.div`
  i {
    font-size: 10px;
    cursor: pointer;
  }
`
const SearchGroup = withRouter(
  clickOutside(
    class extends PureComponent {
      static propTypes = {
        location: PropTypes.object,
        history: PropTypes.object
      }
      state = {
        searching: false
      }

      componentDidMount = () => {
        if (this.input.value) {
          this.input.focus()
        }
      }

      handleClickOutside = () => {
        this.input.blur()
        this.setState({ searching: false })
      }
      onClickSearch = e => {
        this.input.focus()
        this.setState({ searching: true })
      }
      removeSearchQueryParams = () => {}
      onClickRemoveSearch = e => {
        this.input.blur()
        this.setState({ searching: false })
        this.input.value = ''
        const search = queryString.parse(this.props.location.search)
        delete search['search']
        this.props.history.push({ search: queryString.stringify(search) })
      }
      onSearch = e => {
        e.preventDefault()
        const search = {
          ...queryString.parse(this.props.location.search),
          search: this.input.value
        }
        delete search['page']
        if (!this.input.value) {
          delete search['search']
        }
        this.props.history.push({ search: queryString.stringify(search) })
      }
      registerRef = input => {
        this.input = input
      }
      render () {
        return (
          <SearchGroupContainer onSubmit={this.onSearch} noValidate search={this.state.searching}>
            <Icon
              name='Search'
              button
              hoverable={!this.state.searching}
              onClick={this.onClickSearch}
            />
            <InlineInput
              search={this.state.searching}
              registerRef={this.registerRef}
              onPressEscape={this.handleClickOutside}
              defaultValue={queryString.parse(this.props.location.search).search}
              suffix={
                <CloseIconInputContainer onClick={this.onClickRemoveSearch}>
                  <Icon name='Close' />
                </CloseIconInputContainer>
              }
            />
          </SearchGroupContainer>
        )
      }
    }
  )
)
