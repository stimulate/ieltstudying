import { configureStore } from '@reduxjs/toolkit'
import user from './modules/user'
import app from './modules/app'

const store = configureStore({
  reducer: {
    app,
    user,
  },
})
export default store
