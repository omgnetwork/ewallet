import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import moment from 'moment'

import { Input, Button, Icon, Select } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { getAccountById, updateAccount } from '../omg-account/action'
import { selectGetAccountById } from '../omg-account/selector'
import Copy from '../omg-copy'
import CategoriesFetcher from '../omg-account-category/categoriesFetcher'

const AccountSettingContainer = styled.div`
  a {
    color: inherit;
    padding-bottom: 5px;
    display: block;
  }
  padding-bottom: 50px;
`
const ProfileSection = styled.div`
  padding-top: 40px;
  input {
    margin-top: 40px;
  }
  button {
    margin-top: 40px;
  }
  form {
    display: flex;
    > div {
      display: inline-block;
    }
    > div:first-child {
      margin-right: 40px;
    }
    > div:nth-child(2) {
      max-width: 300px;
      width: 100%;
    }
  }
`
const Avatar = styled(ImageUploaderAvatar)`
  margin: 0;
`
export const NameColumn = styled.div`
  i[name='Copy'] {
    margin-left: 5px;
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B100};
    }
  }
`

const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      currentAccount: selectGetAccountById(state)(props.match.params.accountId)
    }),
    { getAccountById, updateAccount }
  )
)

class AccountSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    getAccountById: PropTypes.func.isRequired,
    updateAccount: PropTypes.func,
    currentAccount: PropTypes.object,
    location: PropTypes.object,
    divider: PropTypes.bool
  }

  constructor (props) {
    super(props)
    this.state = {
      inviteModalOpen: queryString.parse(props.location.search).invite || false,
      name: '',
      description: '',
      avatar: '',
      submitStatus: 'DEFAULT',
      categorySearch: '',
      categorySelect: '',
    }
  }
  componentDidMount () {
    this.setInitialAccountState()
  }
  async setInitialAccountState () {
    const { currentAccount } = this.props;
    if (currentAccount) {
      this.setState({
        name: currentAccount.name,
        description: currentAccount.description,
        avatar: currentAccount.avatar.original,
        categorySelect: currentAccount.categories.data[0],
        categorySearch: currentAccount.categories.data[0].name
      })
    } else {
      const result = await this.props.getAccountById(this.props.match.params.accountId)
      if (result.data) {
        this.setState({
          name: result.data.name,
          description: result.data.description || '',
          avatar: result.data.avatar.original || '',
          categorySelect: result.data.categories.data[0] || '',
          categorySearch: result.data.categories.data[0].name || ''
        })
      }
    }
  }
  onChangeImage = ({ file }) => {
    this.setState({ image: file })
  }
  onChangeName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeDescription = e => {
    this.setState({ description: e.target.value })
  }
  onClickUpdateAccount = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      const result = await this.props.updateAccount({
        accountId: this.props.match.params.accountId,
        name: this.state.name,
        description: this.state.description,
        avatar: this.state.image
      })

      if (result.data) {
        this.setState({ submitStatus: 'SUBMITTED' })
      } else {
        this.setState({ submitStatus: 'FAILED' })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }

  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderInviteButton = () => {
    return (
      <InviteButton size='small' onClick={this.onClickInviteButton} key={'create'}>
        <Icon name='Plus' /> <span>Invite Member</span>
      </InviteButton>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'updated_at') {
      return moment(data).format()
    }
    if (key === 'username') {
      return data || '-'
    }
    if (key === 'status') {
      return data === 'active' ? 'Active' : 'Pending'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <span>{data}</span> <Copy data={data} />
        </NameColumn>
      )
    }
    return data
  }
  onChangeCategory = e => {
    this.setState({
      categorySearch: e.target.value,
      categorySelect: ''
    });
  }
  onSelectCategory = category => {
    this.setState({
      categorySearch: category.name,
      categorySelect: category
    });
  }
  renderCategoriesPicker = ({ data: categories = [] }) => (
    <Select
      placeholder="Category"
      onSelectItem={this.onSelectCategory}
      onChange={this.onChangeCategory}
      value={this.state.categorySearch}
      options={categories.map(category => ({
        key: category.id,
        value: category.name,
        ...category
      }))}
    />
  )
  get checkDiff() {
    const propsCategoryId = _.get(this.props.currentAccount, 'categories.data[0].id')
    const stateCategoryId = _.get(this.state.categorySelect, 'id')
    const sameCategory = propsCategoryId && propsCategoryId === stateCategoryId

    return this.props.currentAccount.name === this.state.name &&
      this.props.currentAccount.description === this.state.description &&
      !this.state.image &&
      !sameCategory &&
      this.state.categorySelect
  }
  renderAccountSettingTab = () => (
    <ProfileSection>
      {this.props.currentAccount && (
        <form onSubmit={this.onClickUpdateAccount} noValidate>
          <Avatar
            onChangeImage={this.onChangeImage}
            size='180px'
            placeholder={this.state.avatar}
          />
          <div>
            <Input
              prefill
              placeholder={'Name'}
              value={this.state.name}
              onChange={this.onChangeName}
            />
            <Input
              placeholder={'Description'}
              value={this.state.description}
              onChange={this.onChangeDescription}
              prefill
            />
            <CategoriesFetcher
              {...this.state}
              render={this.renderCategoriesPicker}
              search={this.state.categorySearch}
              perPage={100}
            />
            <Button
              size='small'
              type='submit'
              key={'save'}
              disabled={!this.checkDiff}
              loading={this.state.submitStatus === 'SUBMITTING'}
            >
              <span>Save Changes</span>
            </Button>
          </div>
        </form>
      )}
    </ProfileSection>
  )
  render () {
    return (
      <AccountSettingContainer>
        <TopNavigation divider={this.props.divider}
          title='Account Settings'
          secondaryAction={false}
          types={false}
        />
        {this.renderAccountSettingTab()}
      </AccountSettingContainer>
    )
  }
}
export default enhance(AccountSettingPage)
