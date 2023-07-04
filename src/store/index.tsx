import { configureStore } from '@reduxjs/toolkit'
import user, { UserStateType } from './modules/user'
import app, { AppStateType } from './modules/app'

export type StoreStateType = {
  app: AppStateType
  user: UserStateType
}

const store = configureStore({
  reducer: {
    app,
    user,
  },
})
export default store
