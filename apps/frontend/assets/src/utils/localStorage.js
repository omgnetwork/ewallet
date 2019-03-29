export default {
  set: (key, payload) => {
    try {
      const stringifiedPayload = JSON.stringify(payload)
      window.localStorage.setItem(key, stringifiedPayload)
      return true
    } catch (error) {
      throw new Error(`cannot stringify json from localStorage module with payload ${payload}`)
    }
  },
  get: key => {
    try {
      return JSON.parse(window.localStorage.getItem(key))
    } catch (error) {
      throw new Error(`cannot parse json from localStorage module with key ${key}`)
    }
  }
}
