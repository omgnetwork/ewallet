import React from 'react'
import { shallow } from 'enzyme'
import { LinkWithAccount } from './index'
describe('omg-link', () => {
  test('should return correct props for react-router link when giving pathname and search as object', () => {
    // Render a checkbox with label in the document
    const mockWithRouterProps = {
      match: { params: { accountId: 'id' } },
      location: { pathname: '/testPath' },
      to: { pathname: '/goHere', search: '?testQuery=2' }
    }
    const wrapper = shallow(<LinkWithAccount {...mockWithRouterProps} />)
    expect(wrapper.instance().createPathWithAccount()).toEqual({
      pathname: '/id/goHere',
      search: '?testQuery=2'
    })
  })
  test('should return correct props for react-router link when giving pathname and search as string', () => {
    // Render a checkbox with label in the document
    const mockWithRouterProps = {
      match: { params: { accountId: 'id' } },
      location: { pathname: '/testPath' },
      to: '/goThere'
    }
    const wrapper = shallow(<LinkWithAccount {...mockWithRouterProps} />)
    expect(wrapper.instance().createPathWithAccount()).toEqual({
      pathname: '/id/goThere'
    })
  })
})
