import { Reducer } from 'redux'
import { UserAction, UserInfo } from '../action/userAction'
import userState, { UserStateType } from '../state/userState'

const userReducer: Reducer = (state = userState, action) => {
  switch (action.type) {
    case 'ChangeName':
      return { ...state, name: action.payload }
    case 'ChangeAge':
      return { ...state, age: Number(action.payload) }
    case 'exit':
      return { ...state, id: null }
    case 'GetUserInfo':
      // debugger
      return {
        ...state,
        id: (action.payload as UserInfo).userId,
        name: (action.payload as UserInfo).userName,
        age: (action.payload as UserInfo).userAge,
        phone: (action.payload as UserInfo).userPhone,
      }
    default:
      return state
  }
}

export default userReducer
