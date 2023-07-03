import { Reducer } from 'redux'
import { UserAction } from '../action/userAction'
import userState, { UserStateType } from '../state/userState'

const userReducer: Reducer<UserStateType, UserAction> = (
  state = userState,
  action
) => {
  switch (action.type) {
    case 'ChangeName':
      return { ...state, name: action.payload }
    case 'ChangeAge':
      return { ...state, age: Number(action.payload) }
    default:
      return state
  }
}

export default userReducer
