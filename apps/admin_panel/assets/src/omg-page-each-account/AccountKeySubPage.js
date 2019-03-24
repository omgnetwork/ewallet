import React, { useState } from 'react'
import AdminKeySection from '../omg-page-api/AdminKeySection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
import AccountKeyFetcher from '../omg-account/accountKeyFetcher'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
const AccountKeySubPageContainer = styled.div`
  button {
    padding-left: 30px;
    padding-right: 30px;
  }
`

export default withRouter(function AccountKeySubPage (props) {
  const [createAdminKeyModalOpen, setCreateAdminKeyModalOpen] = useState(false)
  return (
    <AccountKeySubPageContainer>
      <TopNavigation
        title='Keys'
        divider={false}
        buttons={[
          <Button key='key' onClick={e => setCreateAdminKeyModalOpen(true)}>
            Generate key
          </Button>
        ]}
      />
      <AdminKeySection
        fetcher={AccountKeyFetcher}
        query={{
          page: queryString.parse(props.location.search)['page'],
          perPage: 10,
          accountId: props.match.params.accountId
        }}
        createAdminKeyModalOpen={createAdminKeyModalOpen}
        onRequestClose={() => setCreateAdminKeyModalOpen(false)}
      />
    </AccountKeySubPageContainer>
  )
})
