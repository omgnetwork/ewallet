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
const enhance = compose(
  withRouter,
  clickOutside
)

class SearchGroup extends PureComponent {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object
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
  registerRef = input => {
    this.input = input
  }
  render () {
    return (
      <SearchGroupContainer onSubmit={this.onSearch} noValidate search={this.state.searching}>
        <Icon name='Search' button hoverable={!this.state.searching} onClick={this.onClickSearch} />
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

export default enhance(SearchGroup)
