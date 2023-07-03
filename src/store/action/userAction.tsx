export type UserAction = {
  type: string
  payload: string
}
function changeStoreName(name: string): UserAction {
  return {
    type: 'ChangeName',
    payload: name,
  }
}
function changeStoreAge(age: string): UserAction {
  return {
    type: 'ChangeAge',
    payload: age,
  }
}
export default {
  changeStoreName,
  changeStoreAge,
}
