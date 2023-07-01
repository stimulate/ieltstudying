import { combineReducers } from 'redux'
import userReducer from './userReducer'
import appReducer from './appReducer'

const reducer = combineReducers({
  user: userReducer,
  app: appReducer,
})
export default reducer
