export class NewAccountParams {
  constructor(attrs) {
    this.name = attrs.name;
    this.description = attrs.description;
  }

  params() {
    return JSON.stringify(this);
  }
}

export class GetAccountsParams {
  constructor(attrs) {
    this.query = attrs.query;
  }

  params() {
    return JSON.stringify(this);
  }
}
