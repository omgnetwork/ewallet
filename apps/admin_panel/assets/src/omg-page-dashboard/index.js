import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Bar } from 'react-chartjs-2'
import styled from 'styled-components'
import { Button, Icon, RatioBar } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import CurrentAccountProvider from '../omg-account-current/currentAccountProvider'
const number = new Array(30).fill().map((x, i) => i)
const data = {
  labels: number,
  datasets: [
    {
      label: 'Credit',
      backgroundColor: 'rgba(0,0,0,0.7)',
      borderWidth: 1,
      data: [
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40
      ],
      stack: 'a'
    },
    {
      label: 'Debit',
      backgroundColor: '#A4C4F8',
      borderWidth: 1,
      data: [
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40,
        65,
        59,
        80,
        81,
        56,
        55,
        40
      ],
      stack: 'a'
    }
  ]
}
const ChartContainer = styled.div`
  width: 100%;
  margin-top: 60px;
`
const SectionsContainer = styled.div`
  display: flex;
`
const SectionContainer = styled.div`
  flex: 1 1 auto;
`
const SubTitle = styled.div`
  font-size: 10px;
  letter-spacing: 1px;
  font-weight: 600;
  color: ${props => props.theme.colors.B100};
`
export default class Dashboard extends Component {
  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderCurrentAccountSection = ({ currentAccount }) => {
    return (
      <SectionContainer>
        <Section title={currentAccount.name || '...'}>
          <DetailGroup><b>Created at:</b> <span>{currentAccount.created_at}</span></DetailGroup>
          <DetailGroup><b>ID:</b> <span>{currentAccount.id}</span></DetailGroup>
          <DetailGroup><b>Description:</b> <span>{currentAccount.descrition || '-'}</span></DetailGroup>
          <DetailGroup><b>Group:</b> <span>{currentAccount.group || '-'}</span></DetailGroup>
          <DetailGroup><b>Account type:</b> <span>{currentAccount.master ? 'Master' : 'Child'}</span></DetailGroup>
        </Section>
        {/* <Section title={'History'} /> */}
      </SectionContainer>
    )
  }
  render () {
    return (
      <div>
        <TopNavigation
          // buttons={}
          title='Dashboard'
          types={false}
          secondaryAction={false}
        />
        <SectionsContainer>
          <CurrentAccountProvider render={this.renderCurrentAccountSection} />
          {/* <SectionContainer>
            <Section title={'Token Status'}>
              <RatioBar
                title='TOKEN PROPORTION'
                dataSource={[
                  { percent: 20, content: 'transaction', color: '#A4C4F8' },
                  { percent: 80, content: 'transaction', color: 'rgba(0,0,0,0.7)' }
                ]}
              />
              <ChartContainer>
                <SubTitle>TRANSACTIONS TREND</SubTitle>
                <Bar
                  height={250}
                  data={data}
                  options={{
                    maintainAspectRatio: false,
                    scales: {
                      xAxes: [
                        {
                          stacked: true,
                          barPercentage: 0.7,
                          gridLines: false
                        }
                      ],
                      yAxes: [
                        {
                          stacked: true,
                          gridLines: false
                        }
                      ]
                    }
                  }}
                />
              </ChartContainer>
            </Section>
          </SectionContainer> */}
        </SectionsContainer>
      </div>
    )
  }
}
