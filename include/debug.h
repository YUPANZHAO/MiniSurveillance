#ifndef _DEBUG_H_
#define _DEBUG_H_

#include <iostream>

namespace ZYP {

template <typename T>
void debug(T value) {
#ifdef _DEBUG
    std::cout << value << std::endl;
#endif // _DEBUG
}

template <typename T, typename...Args>
void debug(T value, Args...args) {
#ifdef _DEBUG
    std::cout << value << ' ';
    debug(args...);
#endif // _DEBUG
}

} // namespace ZYP

#endif // _DEBUG_H_
