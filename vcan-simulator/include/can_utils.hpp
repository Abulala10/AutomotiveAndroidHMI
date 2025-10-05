#ifndef CAN_UTILS_HPP
#define CAN_UTILS_HPP

#include <vector>
#include <string>
using namespace std;

// Returns all available CAN interfaces
vector<string> list_can_interfaces(int s);

#endif