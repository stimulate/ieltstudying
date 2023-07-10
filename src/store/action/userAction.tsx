import { ThunkAction } from 'redux-thunk'
import { RootState } from '..'

export type UserAction = {
  type: string
  payload: string | UserInfo
}

// 用户详情
export type UserInfo = {
  userId: string
  userName: string
  userAge: number
  userPhone: string
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

function exit(userId: string): UserAction {
  return {
    type: 'exit',
    payload: userId,
  }
}

function getUserInfo(userInfo: UserInfo): UserAction {
  return {
    type: 'GetUserInfo',
    payload: userInfo,
  }
}

// 处理异步操作
// ThunkAction: 处理action 返回函数的类型，总共有4个泛型参数。
// 泛型参数类型，
// 第一个参数：返回值的类型
// 第二个参数：跟的state类型
// 第三个参数：额外参数的类型
// 第四个参数：下面需要进行分发action创建函数的类型
export function fetchUserInfoAsync(
  userId: string
): ThunkAction<Promise<void>, RootState, any, UserAction> {
  return async (dispatch, getState) => {
    // debugger
    let resp = await fetchUserInfoById(userId)
    // debugger
    dispatch(getUserInfo(resp.data))
  }
}

// 模拟查询用户详情的接口
export function fetchUserInfoById(userId: string) {
  return new Promise<{ data: UserInfo }>((resolve) =>
    setTimeout(
      () =>
        resolve({
          data: {
            userId,
            userName: '模拟用户',
            userAge: 28,
            userPhone: '13006187657',
          },
        }),
      3000
    )
  )
}

export default {
  changeStoreName,
  changeStoreAge,
  fetchUserInfoAsync,
  exit,
}
