// export type UserStateType = {
//   name: string
//   age: number
// }
// const userState: UserStateType = {
//   name: '小张',
//   age: 18,
// }
// export default userState

export type UserStateType = {
  id: string | null
  name: string
  age: number
  phone: string
}

const userState: UserStateType = {
  id: '01',
  name: '小张',
  age: 18,
  phone: '7798232131',
}

export default userState
