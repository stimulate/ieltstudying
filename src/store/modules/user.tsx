import { createSlice } from '@reduxjs/toolkit'

export type UserStateType = {
  name: string
  age: number
}

const userState: UserStateType = {
  name: '小明',
  age: 18,
}

const user = createSlice({
  // 命名空间，name值会作为action type的前缀
  name: 'user',
  // 初始化状态
  initialState: userState,
  // 1.定义reducer更新状态函数  2.组件中dispatch使用的action函数
  reducers: {
    changeName: (state, action) => {
      state.name = action.payload
    },
    ChangeAge: (state, action) => {
      state.age = Number(action.payload)
    },
  },
})
// 导出action函数
export const { changeName, ChangeAge } = user.actions

// 导出reducer,用与创建store
export default user.reducer
