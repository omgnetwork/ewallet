import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon, Input, PlainButton } from '../omg-uikit'
import CategoriesProvider from '../omg-account-category/categoriesProvider'
const CategoryContainer = styled.div`
  position: relative;
  text-align: left;
  height: 100%;
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
  position: absolute;
  top: auto;
  bottom: 0;
  text-align: center;
  left: 0;
  right: 0;
  padding: 20px 25px;
  border-top: 1px solid ${props => props.theme.colors.S400};
  color: ${props => props.theme.colors.BL400};
  a {
    vertical-align: middle;
    margin-left: 5px;
  }
`
const CreateNewGroupActionContainer = styled.div``
const PlainButtonContainer = styled.div`
  margin-top: 15px;
  text-align: right;
  button {
    font-size: 14px;
  }
`
export default class ChooseCategoryStage extends Component {
  static propTypes = {
    onClickBack: PropTypes.func
  }
  state = { createNewGroup: false }
  onClickCreateNewGroup = e => {
    this.setState({ createNewGroup: true })
  }
  onClickCreateGroup = e => {
    this.setState({ createNewGroup: false })
  }
  renderCategories = ({ categories, loadingStatus }) => {
    return (
      <CategoryContainer>
        <TopBar>
          <Icon name='Chevron-Left' onClick={this.props.onClickBack} />
          <Title>Add to Category</Title>
        </TopBar>
        <SearchContainer>
          <SearchBar>
            <Icon name='Search' />
            <InputSearch />
          </SearchBar>
          <SearchResult>
            <SearchItem active>
              <Icon name='Checkmark' />
              <span>None</span>
            </SearchItem>
            <SearchItem>
              <Icon name='Checkmark' />
              <span>None 2</span>
            </SearchItem>
            <SearchItem>
              <Icon name='Checkmark' />
              <span>None 3</span>
            </SearchItem>
            <SearchItem>
              <Icon name='Checkmark' />
              <span>None 4</span>
            </SearchItem>
          </SearchResult>
        </SearchContainer>
        <BottomBar>
          {this.state.createNewGroup ? (
            <CreateNewGroupActionContainer>
              <Input
                normalPlaceholder='Enter group name'
                autofocus
                onPressEnter={this.onClickCreateGroup}
              />
              <PlainButtonContainer>
                <PlainButton onClick={this.onClickCreateGroup}>Create</PlainButton>
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
    return <CategoriesProvider render={this.renderCategories} {...this.props} {...this.state} />
  }
}
