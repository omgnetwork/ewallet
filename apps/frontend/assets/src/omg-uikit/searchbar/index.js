import React, { useState } from 'react'
import styled from 'styled-components'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'

import Input from '../input'
import Suffix from './suffix'

const StyledInput = styled(Input)`
  width: 250px;
  input {
    ::placeholder {
      font-size: 14px;
    }
  }
`

const onSearch = (value, history, search) => {
  const _search = {
    ...queryString.parse(search),
    search: value
  }
  delete _search['page']
  if (!value) {
    delete _search['search']
  }
  history.push({ search: queryString.stringify(_search) })
}

const debouncedSearch = _.debounce(onSearch, 500)

const SearchBar = withRouter(
  ({ placeholder = 'Search', history, location: { search } }) => {
    const { search: _search } = queryString.parse(search)
    const [ value, setValue ] = useState(_search || '')

    const clearSearch = () => {
      setValue('')
      const _search = queryString.parse(search)
      delete _search['search']
      history.push({ search: queryString.stringify(_search) })
    }

    const handleChange = e => {
      setValue(e.target.value)
      debouncedSearch(e.target.value, history, search)
    }

    return (
      <StyledInput
        normalPlaceholder={placeholder}
        value={value}
        onChange={handleChange}
        suffix={<Suffix onClick={clearSearch} />}
      />
    )
  }
)

export default SearchBar
