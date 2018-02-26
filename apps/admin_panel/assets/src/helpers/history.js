import { createBrowserHistory } from 'history';
import { ADMIN_PANEL_BASE_DIR } from '../omisego/config';

export default createBrowserHistory({ basename: ADMIN_PANEL_BASE_DIR });
