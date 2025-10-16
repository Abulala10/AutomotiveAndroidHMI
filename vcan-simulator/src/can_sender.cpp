#include "../include/can_sender.hpp"
#include "../include/can_utils.hpp"
#include <linux/can.h>
#include <linux/can/raw.h>
#include <sys/socket.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <ctime>

#define INTERFACE_NAME "vcan0"

using namespace std;


int main(int argc, char* argv[])
{
    int s = create_can_socket();
    cout << "Socket Generated.\n";
    return 0;
}

int create_can_socket()
{
    /*
        +---------------------------+
        | struct ifreq (ifr)        |
        |---------------------------|
        | ifr_name: "vcan0"         | <-- Interface name you set
        | ifr_ifindex: 3            | <-- Filled by ioctl(SIOCGIFINDEX)
        +---------------------------+
                      |
                      v
        +---------------------------+
        | struct sockaddr_can (addr)|
        |---------------------------|
        | can_family: AF_CAN        | <-- Protocol family for CAN sockets
        | can_ifindex: 3            | <-- Interface index from ifr.ifr_ifindex
        +---------------------------+
                      |
                      v
        +---------------------------+
        | socket (sock)             |
        |---------------------------|
        | Bound to addr              | <-- Can send/receive CAN frames on "vcan0"
        +---------------------------+

    */
    int s = socket(PF_CAN, SOCK_RAW, CAN_RAW); 
    
    if (s < 0)
    {
        perror("Socket creation failed");
        return 1;
    }

    // vector<string> lst_can_ifaces = list_can_interfaces(s);
    // print_vector(lst_can_ifaces);

    // Interface request
    struct ifreq ifr;
    strncpy(ifr.ifr_name, INTERFACE_NAME, IFNAMSIZ - 1); // dest, src, n(16) setting the inteface name.
    ifr.ifr_name[IFNAMSIZ - 1] = '\0'; // Ensures the str is properly null terminated.

    // cout << INTERFACE << endl;
    if (ioctl(s, SIOCGIFINDEX, &ifr) < 0) // ioctl -> inp/out control & generic interface to communicate with device drivers
    {
        // NOTE ioctl returns -1 on failure.
        // SIOCGIFINDEX -  To retrieve the index of a network interface
        perror("ioctl failed");
        close(s);
        return -1;
    }
    
    struct sockaddr_can addr;
    memset(&addr, 0, sizeof(addr)); // Clear structure in the memory and set value to 0
    addr.can_family = AF_CAN; // CAN Family
    addr.can_ifindex = ifr.ifr_ifindex; // providing with index
    
    if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) 
    {
        perror("Bind failed");
        close(s);
        return -1;
    }
    
    std::cout << "CAN socket created and bound to " << INTERFACE_NAME << endl;
    return s;

}