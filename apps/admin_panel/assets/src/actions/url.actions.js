import { formatURL, processURL } from '../helpers/urlFormatter';
import defaultPagination from '../constants/pagination.constants';

class URLActions {
  static updateURL(push, url, params = {}) {
    push(formatURL(url, params));
  }

  static processURLParams(location, onCompleted) {
    const params = processURL(location);
    const query = params.query ? params.query : '';
    const page = params.page ? parseInt(params.page, 10) : defaultPagination.PAGE;
    const per = params.per ? Math.min(parseInt(params.per, 10), defaultPagination.PER) :
      defaultPagination.PER;
    onCompleted({ query, page, per });
  }
}

export default URLActions;
