import { legacy_createStore as createStore, applyMiddleware } from 'redux'
import thunk from 'redux-thunk'
import reducer from './reducer/index'
import { UserAction } from './action/userAction'

const store = createStore(reducer, applyMiddleware<UserAction>(thunk))

// 从 store 本身推断出 `RootState` 和 `AppDispatch` 类型
export type RootState = ReturnType<typeof store.getState>

export default store
