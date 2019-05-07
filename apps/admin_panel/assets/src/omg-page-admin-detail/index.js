import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import moment from 'moment'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'

import { Id } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import AdminProvider from '../omg-admins/adminProvider'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'

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
const enhance = compose(
  withTheme,
  withRouter
)
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object
  }
  renderTopBar = admin => {
    return (
      <TopNavigation
        divider={false}
        title={admin.email}
        searchBar={false}
      />
    )
  }
  renderDetail = admin => {
    return (
      <Section title={{ text: 'Details', icon: 'Portfolio' }}>
        <DetailGroup>
          <b>ID:</b><Id>{admin.id}</Id>
        </DetailGroup>
        <DetailGroup>
          <b>Email:</b> <span>{admin.email || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Global Role:</b> <span>{_.startCase(admin.global_role) || '-'}</span>
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
