import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'

import clickOutside from '../enhancer/clickOutside'
import { Icon, Input } from '../omg-uikit'

const SearchGroupContainer = styled.form`
  display: inline-block;
  vertical-align: middle;
  i {
    vertical-align: bottom;
    display: inline-block;
  }
`
const IconContainer = styled.div`
  display: inline;
  :hover {
    i {
      transition: all 100ms ease-in-out;
      color: ${props => props.hoverable && props.theme.colors.B100}
    }
  }
`
const InlineInput = styled(Input)`
  display: inline-block;
  width: ${props => props.search ? '150px' : '0'};
  opacity: ${props => props.search ? 1 : 0};
  overflow: hidden;
  transition: width 0.2s ease-in-out, opacity 0.2s ease-in-out 0.2s;
`
const CloseIconInputContainer = styled.div`
  opacity: ${props => props.open ? 1 : 0};
  transition: opacity 0.2s ease-in-out 0.4s;
  i {
    font-size: 10px;
    cursor: pointer;
  }
`
const enhance = compose(
  withRouter,
  clickOutside
)

class SearchGroup extends PureComponent {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    debounced: PropTypes.number
  }
  state = {
    searching: false
  }

  componentDidMount = () => {
    if (this.input.value) {
      this.setState({ searching: true })
    }
  }
  handleClickOutside = () => {
    this.input.blur()
    this.setState({ searching: this.input.value })
  }
  onClickSearch = e => {
    this.input.focus()
    this.setState({ searching: true })
  }

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

  debouncedSearch = _.debounce(this.onSearch, this.props.debounced);
  handleOnChange = (e) => {
    e.persist()
    if (this.props.debounced) {
      this.debouncedSearch(e)
    }
  }
  registerRef = input => {
    this.input = input
  }
  render () {
    return (
      <SearchGroupContainer onSubmit={this.onSearch} noValidate search={this.state.searching}>
        <IconContainer hoverable={!this.state.searching}>
          <Icon
            name='Search'
            button
            onClick={this.onClickSearch}
          />
        </IconContainer>
        <InlineInput
          {...this.props}
          search={this.state.searching}
          registerRef={this.registerRef}
          onPressEscape={this.handleClickOutside}
          onChange={this.handleOnChange}
          defaultValue={queryString.parse(this.props.location.search).search}
          suffix={
            <CloseIconInputContainer open={this.state.searching} onClick={this.onClickRemoveSearch}>
              <Icon name='Close' />
            </CloseIconInputContainer>
          }
        />
      </SearchGroupContainer>
    )
  }
}

export default enhance(SearchGroup)
