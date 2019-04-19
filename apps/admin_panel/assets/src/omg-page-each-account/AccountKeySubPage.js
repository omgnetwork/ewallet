import React, { useState } from 'react'
import AdminKeySection from '../omg-page-api/AdminKeySection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
import AccountKeyFetcher from '../omg-account/accountKeyFetcher'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import { createSearchAdminSubKeyQuery } from '../omg-access-key/searchField'
import AssignKeyModal from '../omg-assign-key-account-modal'
const AccountKeySubPageContainer = styled.div``
const AssignButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
`

export default withRouter(function AccountKeySubPage (props) {
  const [createAdminKeyModalOpen, setCreateAdminKeyModalOpen] = useState(false)
  const [fetcher, setFetcher] = useState(_.noop)
  const { search, access_key_page } = queryString.parse(props.location.search)
  return (
    <AccountKeySubPageContainer>
      <TopNavigation
        title='Keys'
        divider={false}
        buttons={[
          <Button size='small' onClick={e => onClickCreateAdminKey} styleType={'secondary'}>
            <span>Generate Admin Key</span>
          </Button>,
          <AssignButton key='key' onClick={e => setCreateAdminKeyModalOpen(true)}>
            Assign Admin Key
          </AssignButton>
        ]}
      />
      <AdminKeySection
        fetcher={AccountKeyFetcher}
        registerFetch={fetcher => setFetcher(fetcher)}
        columnsAdminKeys={[
          { key: 'name', title: 'NAME' },
          { key: 'key', title: 'ACCESS KEY' },
          { key: 'global_role', title: 'GLOBAL ROLE' },
          { key: 'account_role', title: 'ACCOUNT ROLE' },
          { key: 'created_at', title: 'CREATED AT' },
          { key: 'status', title: 'STATUS' }
        ]}
        query={{
          page: access_key_page,
          perPage: 10,
          accountId: props.match.params.accountId,
          ...createSearchAdminSubKeyQuery(search)
        }}
      />
      <AssignKeyModal
        onSubmitSuccess={() => fetcher.fetch()}
        open={createAdminKeyModalOpen}
        accountId={props.match.params.accountId}
        onRequestClose={() => setCreateAdminKeyModalOpen(false)}
      />
    </AccountKeySubPageContainer>
  )
})
