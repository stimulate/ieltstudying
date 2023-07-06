import { configureStore } from '@reduxjs/toolkit'
import user, { UserStateType } from './modules/user'
import app, { AppStateType } from './modules/app'
// export type StoreStateType = {
//   app: AppStateType
//   user: UserStateType
// }

const store = configureStore({
  reducer: {
    app,
    user,
  },
})

// 从 store 本身推断出 `RootState` 和 `AppDispatch` 类型
export type RootState = ReturnType<typeof store.getState>
// 推断出类型: {posts: PostsState, comments: CommentsState, users: UsersState}
export type AppDispatch = typeof store.dispatch

export default store
