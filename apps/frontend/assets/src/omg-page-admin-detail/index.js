import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import moment from 'moment'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'

import TopNavigation from '../omg-page-layout/TopNavigation'
import AdminProvider from '../omg-admins/adminProvider'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import { Button, Select, Id } from '../omg-uikit'
import { updateAdmin } from '../omg-admins/action'
const UserDetailContainer = styled.div`
  padding-bottom: 20px;
  b {
    width: 150px;
    display: inline-block;
  }
`
const ContentDetailContainer = styled.div`
  display: flex;
`
const DetailContainer = styled.div`
  flex: 1 1 50%;
  :first-child {
    margin-right: 20px;
  }
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`
const StyledSelect = styled(Select)`
  display: inline-block;
  vertical-align: middle;
`
const enhance = compose(
  withTheme,
  withRouter,
  connect(
    null,
    { updateAdmin }
  )
)
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    updateAdmin: PropTypes.func.isRequired
  }
  state = { editing: false, saving: false }

  renderButtons (admin) {
    return this.state.editing
      ? [
        <Button
          key='cancel'
          styleType='secondary'
          onClick={e =>
            this.setState({ editing: false, editAdminGlobalRole: null })
          }
        >
            Cancel
        </Button>,
        <Button
          key='save'
          onClick={this.onClickSave}
          disabled={!this.state.editAdminGlobalRole}
          loading={this.state.saving}
        >
            Save
        </Button>
      ]
      : [
        <Button key='edit' onClick={e => this.setState({ editing: true })}>
            Edit
        </Button>
      ]
  }
  renderTopBar = admin => {
    return (
      <TopNavigation
        divider={false}
        title={admin.email}
        secondaryAction={false}
        buttons={this.renderButtons(admin)}
      />
    )
  }
  onSelectGlobalRole = data => {
    this.setState({ editAdminGlobalRole: data.key })
  }
  onClickSave = async () => {
    this.setState({ saving: true })
    const result = await this.props.updateAdmin({
      id: this.props.match.params.adminId,
      globalRole: this.state.editAdminGlobalRole
    })
    if (result.data) {
      this.setState({ editing: false, saving: false })
    } else {
      this.setState({ saving: false })
    }
  }
  renderDetail = admin => {
    return (
      <Section title={{ text: 'Details', icon: 'Option-Horizontal' }}>
        <DetailGroup>
          <b>ID:</b>
          <Id>{admin.id}</Id>
        </DetailGroup>
        <DetailGroup>
          <b>Email:</b> <span>{admin.email || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b
            style={{
              verticalAlign: this.state.editing ? 'middle' : 'baseline'
            }}
          >
            Global Role:
          </b>{' '}
          {this.state.editing ? (
            <StyledSelect
              normalPlaceholder='Global role'
              onSelectItem={this.onSelectGlobalRole}
              value={_.startCase(
                this.state.editAdminGlobalRole || admin.global_role
              )}
              options={['super_admin', 'admin', 'viewer'].map(role => ({
                key: role,
                value: _.startCase(role)
              }))}
            />
          ) : (
            <span>{_.startCase(admin.global_role) || '-'}</span>
          )}
        </DetailGroup>
        <DetailGroup>
          <b>Created At:</b> <span>{moment(admin.created_at).format()}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Updated At:</b> <span>{moment(admin.updated_at).format()}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderUserDetailContainer = admin => {
    return (
      <ContentContainer>
        {this.renderTopBar(admin)}
        <ContentDetailContainer>
          <DetailContainer>{this.renderDetail(admin)}</DetailContainer>
        </ContentDetailContainer>
      </ContentContainer>
    )
  }

  renderUserDetailPage = ({ admin }) => {
    return (
      <UserDetailContainer>
        {admin ? this.renderUserDetailContainer(admin) : null}
      </UserDetailContainer>
    )
  }
  render () {
    return (
      <AdminProvider
        render={this.renderUserDetailPage}
        adminId={this.props.match.params.adminId}
        {...this.state}
        {...this.props}
      />
    )
  }
}

export default enhance(TokenDetailPage)
