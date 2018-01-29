import renderer from 'react-test-renderer';
import SignIn from '../SignIn';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const tree =
  renderer.create(SnapshotComponentTester(SignIn, { loading: false, login: jest.fn() })).toJSON();
  expect(tree).toMatchSnapshot();
});
