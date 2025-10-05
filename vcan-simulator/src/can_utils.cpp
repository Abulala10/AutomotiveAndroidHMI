#include "../include/can_utils.hpp"
#include <sys/socket.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cstring>
#include <iostream>

using namespace std;

void print_vector(vector<string> str, string default_str)
{
    for (const auto &iface :  str)
    {
        cout << iface << " ";
    }
    cout << endl;
}

vector<string> list_can_interfaces(int s)
{
    vector<string> can_ifaces;
    if (s < 0) return can_ifaces;

    struct ifreq ifr;
    for (int i = 0; i < 8; i++)
    {
        snprintf(ifr.ifr_name, IFNAMSIZ, "vcan%d", i);
        if (ioctl(s, SIOCGIFINDEX, &ifr) != -1)
            can_ifaces.push_back(ifr.ifr_name);
    }
    // close(s);
    return can_ifaces;
}