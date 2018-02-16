import React from 'react';
import PropTypes from 'prop-types';
import { storiesOf } from '@storybook/react';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';
import store from '../../src/store/store';
import OMGAddMemberForm from '../../src/components/OMGAddMemberForm';

const container = {
  width: '600px',
  paddingLeft: '2rem',
  paddingTop: '2rem',
};

const smallContainer = story => (
  <div style={container}>
    {story()}
  </div>
);
const reduxDecorator = story => (
  <Router>
    <Provider store={store}>
      {story()}
    </Provider>
  </Router>
);

const SEARCH_URI = 'https://api.github.com/search/users';

const GithubMenuItem = ({ user }) => (
  <div>
    <img
      alt="user"
      src={user.avatar_url}
      style={{
        height: '24px',
        marginRight: '10px',
        width: '24px',
      }}
    />
    <span>
      {user.login}
    </span>
  </div>
);

GithubMenuItem.propTypes = {
  user: PropTypes.shape({
    avatar_url: PropTypes.string.isRequired,
    login: PropTypes.string.isRequired,
  }).isRequired,
};

function fetchGithubUsers(query, page = 1) {
  return fetch(`${SEARCH_URI}?q=${query}+in:login&page=${page}&per_page=50`)
    .then(resp => resp.json())
    .then(({ items }) => {
      if (!items) return;
      const options = items.map(i => ({
        avatar_url: i.avatar_url,
        id: i.id,
        login: i.login,
      }));
      return { options };
    });
}

const customMenuItem = option => <GithubMenuItem key={option.id} user={option} />;

const handleSearch = (query, callback) =>
  fetchGithubUsers(query).then(({ options }) => callback(options));

storiesOf('OMGAddMemberForm', module)
  .addDecorator(smallContainer)
  .addDecorator(reduxDecorator)
  .add('Normal state', () => <OMGAddMemberForm labelKey="" />)
  .add('With default value', () => <OMGAddMemberForm defaultInputValue="OmiseGo" labelKey="" />)
  .add('With github users searching', () => (
    <OMGAddMemberForm
      customRenderMenuItem={customMenuItem}
      labelKey="login"
      member={{ email: 'DavidKnott' }}
      onSearch={handleSearch}
    />
  ));
