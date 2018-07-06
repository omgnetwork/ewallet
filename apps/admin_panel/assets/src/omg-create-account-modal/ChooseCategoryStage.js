import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon, Input, PlainButton } from '../omg-uikit'
import CategoriesFetcher from '../omg-account-category/categoriesFetcher'
import { connect } from 'react-redux'
import { createCategory } from '../omg-account-category/action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
const CategoryContainer = styled.div`
  position: relative;
  text-align: left;
  height: 100%;
  display: flex;
  flex-direction: column;
`
const TopBar = styled.div`
  border-bottom: 1px solid ${props => props.theme.colors.S400};
  i {
    cursor: pointer;
    padding: 15px;
    display: inline-block;
    border-right: 1px solid ${props => props.theme.colors.S400};
  }
`
const SearchContainer = styled.div`
  padding: 10px 20px;
  overflow: auto;
  height: 100%;
`
const SearchBar = styled.div`
  display: flex;
  align-items: flex-end;
  i {
    font-size: 18px;
    display: block;
  }
`
const Title = styled.span`
  padding-left: 15px;
`
const InputSearch = styled(Input)`
  padding: 0 22px;
  input {
    border-bottom: 1px solid ${props => props.theme.colors.S400};
  }
`
const SearchResult = styled.div`
  margin-top: 30px;
  padding-right: 20px;
`
const SearchItem = styled.div`
  vertical-align: middle;
  cursor: pointer;
  i {
    opacity: ${props => (props.active ? 1 : 0)};
    vertical-align: baseline;
  }
  > span {
    margin-left: 30px;
    display: inline-block;
    padding: 8px 0;
    font-weight: ${props => (props.active ? 900 : 300)};
  }
  :hover {
    span {
      color: ${props => (props.active ? 'inherit' : props.theme.colors.B500)};
    }
    i {
      opacity: 1;
      color: ${props => (props.active ? 'inherit' : props.theme.colors.S400)};
    }
  }
`
const BottomBar = styled.div`
  background-color: white;
  text-align: center;
  padding: 20px 25px;
  border-top: 1px solid ${props => props.theme.colors.S400};
  color: ${props => props.theme.colors.BL400};
  a {
    vertical-align: middle;
    margin-left: 5px;
  }
`
const CreateNewGroupActionContainer = styled.form``
const PlainButtonContainer = styled.div`
  margin-top: 15px;
  text-align: right;
  button {
    font-size: 14px;
  }
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createCategory }
  )
)
class ChooseCategoryStage extends Component {
  static propTypes = {
    onClickBack: PropTypes.func,
    categories: PropTypes.array,
    createCategory: PropTypes.func,
    onChooseCategory: PropTypes.func,
    category: PropTypes.object,
    match: PropTypes.object
  }
  state = { createNewGroup: false, categoryNameToCreate: '' }
  onClickCreateNewGroup = e => {
    this.setState({ createNewGroup: true })
  }
  onClickCreateCategory = async e => {
    e.preventDefault()
    const result = await this.props.createCategory({
      name: this.state.categoryNameToCreate,
      accountId: this.props.match.params.accountId
    })
    if (result.data.success) {
      this.props.onChooseCategory(result.data.data)
    }
  }
  onChangeInputCreateGroup = e => {
    this.setState({ categoryNameToCreate: e.target.value })
  }
  onChangeInputSearch = e => {
    this.setState({ search: e.target.value })
  }
  renderCategories = ({ data: categories = [] }) => {
    return (
      <CategoryContainer>
        <TopBar>
          <Icon name='Chevron-Left' onClick={this.props.onClickBack} />
          <Title>Add to Category</Title>
        </TopBar>
        <SearchContainer>
          <SearchBar>
            <Icon name='Search' />
            <InputSearch autofocus value={this.state.search} onChange={this.onChangeInputSearch} />
          </SearchBar>
          <SearchResult>
            <SearchItem
              active={_.isEmpty(this.props.category)}
              onClick={e => this.props.onChooseCategory(null)}
            >
              <Icon name='Checked' />
              <span>None</span>
            </SearchItem>
            {categories.map(cat => {
              return (
                <SearchItem
                  onClick={e => this.props.onChooseCategory(cat)}
                  active={_.get(this.props.category, 'id') === cat.id}
                  key={cat.id}
                >
                  <Icon name='Checked' />
                  <span>{cat.name}</span>
                </SearchItem>
              )
            })}
          </SearchResult>
        </SearchContainer>
        <BottomBar>
          {this.state.createNewGroup ? (
            <CreateNewGroupActionContainer onSubmit={this.onClickCreateCategory}>
              <Input
                normalPlaceholder='Enter group name'
                autofocus
                value={this.state.categoryNameToCreate}
                onChange={this.onChangeInputCreateGroup}
              />
              <PlainButtonContainer>
                <PlainButton onClick={this.onClickCreateCategory}>Create</PlainButton>
              </PlainButtonContainer>
            </CreateNewGroupActionContainer>
          ) : (
            <PlainButton onClick={this.onClickCreateNewGroup}>
              <Icon name='Plus' /> Create New Group
            </PlainButton>
          )}
        </BottomBar>
      </CategoryContainer>
    )
  }
  render () {
    return (
      <CategoriesFetcher
        render={this.renderCategories}
        search={this.state.search}
        perPage={100}
      />
    )
  }
}

export default enhance(ChooseCategoryStage)
