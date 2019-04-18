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
  const [assignAdminKeyModalOpen, setAssignAdminKeyModalOpen] = useState(false)
  const [generateAdminKeyModalOpen, setGenerateAdminKeyModalOpen] = useState(false)
  const [fetcher, setFetcher] = useState(_.noop)

  const { search, access_key_page } = queryString.parse(props.location.search)
  const { accountId } = props.match.params;

  return (
    <AccountKeySubPageContainer>
      <TopNavigation
        title='Keys'
        divider={false}
        buttons={[
          <AssignButton key='assign' onClick={e => setAssignAdminKeyModalOpen(true)}>
            Assign
          </AssignButton>,
          <Button key='generate-admin-key' size='small' onClick={e => setGenerateAdminKeyModalOpen(true)} styleType={'secondary'}>
            <span>Generate Admin Key</span>
          </Button>
        ]}
      />
      <AdminKeySection
        accountId={accountId}
        createAdminKeyModalOpen={generateAdminKeyModalOpen}
        onRequestClose={e => setGenerateAdminKeyModalOpen(false)}
        fetcher={AccountKeyFetcher}
        registerFetch={fetcher => setFetcher(fetcher)}
        columnsAdminKeys={[
          { key: 'name', title: 'NAME' },
          { key: 'key', title: 'ACCESS KEY' },
          { key: 'account_role', title: 'ACCOUNT ROLE' },
          { key: 'global_role', title: 'GLOBAL ROLE' },
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
        open={assignAdminKeyModalOpen}
        accountId={props.match.params.accountId}
        onRequestClose={() => setAssignAdminKeyModalOpen(false)}
      />
    </AccountKeySubPageContainer>
  )
})
