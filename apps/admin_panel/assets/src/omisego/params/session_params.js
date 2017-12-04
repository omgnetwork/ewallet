export class LoginParams {
  constructor(attrs) {
    this.username = attrs.username;
    this.password = attrs.password;
  }

  params() {
    return JSON.stringify(this);
  }
}
